class Transaction < ActiveRecord::Base
  self.primary_key = 'tranID'
  self.table_name= 'transactions'
  
  establish_connection :ez_cash
  
  mount_uploader :upload_file, FileUploader
  
  belongs_to :device, :foreign_key => :dev_id, optional: true
  belongs_to :account, :foreign_key => :from_acct_id # Assume from account is the main account
  has_one :transfer, :foreign_key => :ez_cash_tran_id
  belongs_to :company, :foreign_key => "DevCompanyNbr"
  has_one :payment, :foreign_key => "TranID"
  belongs_to :event, optional: true
  
  scope :withdrawals, -> { where(tran_code: ["WDL", "ALL"], sec_tran_code: ["TFR", "", "ALL", "CASH"]) }
  scope :transfers, -> { where(tran_code: ["CARD", "TFR"], sec_tran_code: ["TFR", "CARD"]) }
  scope :reversals, -> { where(tran_code: ["CRED", "TFR"], sec_tran_code: ["TFR", "CRED"]) }
  scope :one_sided_credits, -> { where(tran_code: ["DEP"], sec_tran_code: ["REFD"]) }
  scope :fees, -> { where(tran_code: ["FEE"], sec_tran_code: ["TFR"]) }
  scope :fee_reversals, -> { where(tran_code: ["TFR" "FEEC"], sec_tran_code: ["TFR", "FEEC"]) }
  scope :fees_and_fee_reversals, -> { where(tran_code: ["TFR","FEE","FEEC"], sec_tran_code: ["TFR","FEE","FEEC"]) }
  scope :checks, -> { where(tran_code: ["CHK"], sec_tran_code: ["TFR"]) }
  scope :not_fees, -> { where.not(tran_code: ["FEE"]) }
  scope :not_fees_and_not_withdrawals, -> { where.not(tran_code: ["FEE", "WDL", "ALL"]) }
  
  scope :cuts, -> { where(tran_code: ["CUT"]) }
  scope :adds, -> { where(tran_code: ["ADD"]) }
  scope :adds_and_cuts, -> { where(tran_code: ["ADD", "CUT"]) }
  
  scope :coin_cuts, -> { where(tran_code: ["CUTC"]) }
  scope :coin_adds, -> { where(tran_code: ["ADDC"]) }
  scope :coin_adds_and_cuts, -> { where(tran_code: ["ADDC", "CUTC"]) }
  
  scope :coin_or_cash_adds_and_cuts, -> { where(tran_code: ["ADD", "ADDC", "CUT", "CUTC"]) }
  
  #############################
  #     Instance Methods      #
  #############################
  
  def error_code_description
    error_desc = ErrorDesc.find_by_error_code(error_code)
    unless error_desc.blank?
      return error_desc.short_desc
    else
      return "N/A"
    end
  end
  
  def error_code_long_description
    error_desc = ErrorDesc.find_by_error_code(error_code)
    unless error_desc.blank?
      return error_desc.long_desc
    else
      return "Not Applicable"
    end
  end
  
  def status_description
    tran_status_desc = TranStatusDesc.find_by_tran_status(tran_status)
    unless tran_status_desc.blank?
      return tran_status_desc.short_desc
    else
      return "N/A"
    end
  end
  
  def status_long_description
    tran_status_desc = TranStatusDesc.find_by_tran_status(tran_status)
    unless tran_status_desc.blank?
      return tran_status_desc.long_desc
    else
      return "Not Applicable"
    end
  end
  
  def type
    unless tran_code.blank? and sec_tran_code.blank?
      if (tran_code.strip == "CHK" and sec_tran_code.strip == "TFR")
        return "Check Cashed"
      elsif (tran_code.strip == "CHKP" and sec_tran_code.strip == "TFR")
        return "Positive Check Cashed"
      elsif ((tran_code.strip == "CASH" and sec_tran_code.strip == "TFR") or (tran_code.strip == "DEP" and sec_tran_code.strip == "TFR"))
        return "Cash Deposit"
      elsif (tran_code.strip == "ACH" and sec_tran_code.strip == "TFR")
        return "ACH Deposit"
      elsif (tran_code.strip == "MON" and sec_tran_code.strip == "ORD")
        return "Money Order"
      elsif ((tran_code.strip == "WDL" or tran_code.strip == "ALL") and (sec_tran_code.blank? or sec_tran_code.strip == "TFR" or sec_tran_code.strip == "CASH"))
        return "Withdrawal"
      elsif (tran_code.strip == "WDL" and sec_tran_code.strip == "REVT")
        return "Reverse Withdrawal"
      elsif ((tran_code.strip == "WDL" or tran_code.strip == "ALL") and (sec_tran_code.strip == "TFR" or sec_tran_code.strip == "ALL"))
        return "Withdrawal All"
      elsif ((tran_code.strip == "CARD" or tran_code.strip == "TFR") and (sec_tran_code.strip == "TFR" or sec_tran_code.strip == "CARD"))
        return "Transfer"
      elsif (tran_code.strip == "BILL" and sec_tran_code.strip == "PAY")
        return "Bill Pay"
      elsif (tran_code.strip == "POS" and sec_tran_code.strip == "TFR")
        return "Purchase"
      elsif (tran_code.strip == "PUT" and sec_tran_code.strip == "TFR")
        return "Wire Transfer"
      elsif (tran_code.strip == "FUND" and sec_tran_code.strip == "TFR")
        return "Fund Transfer"
      elsif ((tran_code.strip == "CRED" or tran_code.strip == "TFR") and (sec_tran_code.strip == "TFR" or sec_tran_code.strip == "CRED"))
        return "Account Credit"
      elsif ((tran_code.strip == "FEE" or tran_code.strip == "TFR") and (sec_tran_code.strip == "TFR" or sec_tran_code.strip == "FEE"))
        return "Fee"
      elsif ((tran_code.strip == "FEEC" or tran_code.strip == "TFR") and (sec_tran_code.strip == "TFR" or sec_tran_code.strip == "FEEC"))
        return "Fee Credit"
      elsif (tran_code.strip == "TFR" and sec_tran_code.strip == "PMT")
        return "Balancing"
      else
        return "Unknown"
      end
    end
  end
  
#  def debit?(account_number)
#    bill_pay? or money_order? or withdrawal? or transfer_out?(account_number) or purchase?
#  end

  def debit?
    wire_transfer_out? or bill_pay? or money_order? or withdrawal? or transfer_out? or purchase?
  end
  
  def debit?(account_id)
    fund_transfer_out?(account_id) or wire_transfer_out?(account_id) or bill_pay? or money_order? or withdrawal? or withdrawal_all? or transfer_out?(account_id) or purchase?
  end
  
#  def debit?(account_number)
#    from_acct_nbr == account_number
#  end
  
  def credit?(account_number)
    fund_transfer_in? or wire_transfer_in? or check_cashed? or positive_check_cashed? or cash_deposit? or reverse_withdrawal? or transfer_in? (account_number)
  end
  
  def bill_pay?
    type == "Bill Pay"
  end
  
  def money_order?
    type == "Money Order"
  end
  
  def withdrawal?
    type == "Withdrawal"
  end
  
  def withdrawal_all?
    type == "Withdrawal All"
  end
  
  def reverse_withdrawal?
    type == "Reverse Withdrawal"
  end
  
  def card_transfer?
    type == "Card Transfer"
  end
  
  def check_cashed?
    type == "Check Cashed"
  end
  
  def positive_check_cashed?
    type == "Positive Check Cashed"
  end
  
  def cash_deposit?
    type == "Cash Deposit"
  end
  
  def ach_deposit?
    type == "ACH Deposit"
  end
  
  def purchase?
    type == "Purchase"
  end
  
  def wire_transfer?
    type == "Wire Transfer"
  end
  
  def fund_transfer?
    type == "Fund Transfer"
  end
  
  def fee_transfer?
    type == "Fee"
  end
  
#  def transfer_in?(account_number)
#    card_transfer? and to_acct_nbr == account_number
#  end
  
  def transfer_in?
    card_transfer? and to_acct_id == self.ActID
  end
  
  def wire_transfer_in?
    wire_transfer? and to_acct_id == self.ActID
  end
  
#  def transfer_out?(account_number)
#    card_transfer? and from_acct_nbr == account_number
#  end
  
  def transfer_out?
    card_transfer? and from_acct_id == self.ActID
  end
  
  def transfer_out?(account_id)
    card_transfer? and from_acct_id == account_id
  end
  
  def wire_transfer_out?
    wire_transfer? and from_acct_id == self.ActID
  end
  
  def wire_transfer_out?(account_id)
    wire_transfer? and from_acct_id == account_id
  end
  
  def fund_transfer_out?(account_id)
    fund_transfer? and from_acct_id == account_id
  end
  
  def reversal?
    type == "Account Credit" or type == "Fee Credit"
  end
  
  def error?
    error_code and error_code > 0
  end
  
  
  
#  def account
##    Account.where(ActID: self.ActID).last
#    Account.where(ActID: card_nbr).last
#  end
  
  def images
#    images = Image.where(ticket_nbr: id.to_s)
#    unless images.blank?
#      return images
#    else
#      return []
#    end
    return []
  end
  
  def front_side_check_images
    images = Image.where(ticket_nbr: id.to_s, event_code: "FS")
    unless images.blank?
      return images
    else
      return []
    end
  end
  
  def back_side_check_images
    images = Image.where(ticket_nbr: id.to_s, event_code: "BS")
    unless images.blank?
      return images
    else
      return []
    end
  end
  
  def customer
#    Customer.find(self.custID)
    account.customer unless account.blank?
  end
  
#  def company
#    
#    unless customer.blank?
#      customer.company
#    else
#      unless from_account.blank?  
#        from_account.company 
#      else
#        unless to_account.blank?
#          to_account.company 
#        end
#      end
#    end
#  end
  
  def amount_with_fee
    unless self.ChpFee.blank? or self.ChpFee.zero?
      if self.FeedActID == self.from_acct_id
        return amt_auth + self.ChpFee
      elsif self.FeedActID == self.to_acct_id
        return amt_auth - self.ChpFee
      else
        return amt_auth - self.ChpFee
      end
    else
      return amt_auth
    end
  end
  
  def amount_with_fee(account_id)
    unless self.ChpFee.blank? or self.ChpFee.zero?
      if self.FeedActID == account_id
        if self.from_acct_id == account_id
          return amt_auth + self.ChpFee
        else
          return amt_auth - self.ChpFee
        end
      else
        return amt_auth
      end
    else
      return amt_auth
    end
  end
  
  def total
    unless amt_auth.blank?
      unless self.ChpFee.blank?
        return amt_auth + self.ChpFee
      else
        return amt_auth
      end
    end
  end
  
  def to_account
    Account.where(ActID: to_acct_id).first
  end
  
  def from_account
    Account.where(ActID: from_acct_id).first
  end
  
  def to_account_type
    AccountType.where(AccountTypeID: to_acct_type).first
  end
  
  def from_account_type
    AccountType.where(AccountTypeID: from_acct_type).first
  end
  
  def to_account_customer
    unless to_account.blank?
      to_account.customer
    end
  end
  
  def from_account_customer
    unless from_account.blank?
      from_account.customer
    end
  end
  
  def to_account_customers
    unless to_account.blank?
      to_account.customers
    end
  end
  
  def to_account_customers_list
    to_account_customers.map{|customer| "#{customer.full_name}"}.join(", ").html_safe
  end
  
  def from_account_customers
    unless from_account.blank?
      from_account.customers
    end
  end
  
  def from_account_customers_list
    from_account_customers.map{|customer| "#{customer.full_name}"}.join(", ").html_safe
  end
  
  def reverse
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:ez_cash_txn, message: { TranID: tranID })
    Rails.logger.debug "Response body: #{response.body}"
#    unless response.blank? or response.body.blank? or response.body[:ez_cash_txn_response].blank? or response.body[:ez_cash_txn_response][:return].to_i > 0
#      return true
#    else
#      return false
#    end
    if response.success?
      return response.body[:ez_cash_txn_response]
    else
      return nil
    end
  end
  
  def credit_transaction_transfer
    Transfer.where(club_credit_transaction_id: tranID).first
  end
  
  def credit_transaction_for_transfer?
    not credit_transaction_transfer.blank?
  end
  
  def reversal_transaction
    Transaction.where(OrigTranID: tranID, tran_code: ["CRED", "CRED "], sec_tran_code: ["TFR", "TFR "], error_code: 0).first
  end
  
  def original_transaction
    unless self.OrigTranID.blank? or self.OrigTranID.zero?
      Transaction.find(self.OrigTranID)
    else
      return nil
    end
  end
  
  def reversed?
    reversal_transaction.present?
  end
  
#  def send_text_message_receipt
#    from_customer = from_account.customer
##    to_customer = to_account.customer
#    from_customer_phone = from_customer.user.blank? ? from_customer.phone : from_customer.user.phone
#    unless from_customer_phone.blank?
##      SendSmsWorker.perform_async(cell_phone_number, id, self.CustomerID, self.ClubCompanyNbr, message_body)
##      message = "You have transfered #{ActiveSupport::NumberHelper.number_to_currency(amt_auth)} to #{to_customer.company.name}. Your balance is #{ActiveSupport::NumberHelper.number_to_currency(from_account.Balance)}"
#      message = "#{to_account.customer_name} debited #{ActiveSupport::NumberHelper.number_to_currency(amt_auth)}. Click here to review: https://#{ENV['APPLICATION_HOST']}/transactions/#{self.tranID}/dispute?phone=#{from_customer_phone}"
#      client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
#      client.call(:send_sms, message: { Phone: from_customer_phone, Msg: "#{message}"})
#      Rails.logger.debug "Text message sent to #{from_customer_phone}: #{message}"
#    end
#  end
  
  def send_text_message_receipt
    from_account_customers.each do |from_customer|
      from_customer_phone = from_customer.user.blank? ? from_customer.phone : from_customer.user.phone
      unless from_customer_phone.blank? or self.amt_auth.blank?
#        unless to_customer.blank?
#          message = "You paid #{to_customer.full_name} #{ActiveSupport::NumberHelper.number_to_currency(total)}. Click here to review: https://#{ENV['APPLICATION_HOST']}/transactions/#{self.tranID}/dispute?phone=#{from_customer_phone}"
#        end
        message = "You paid #{to_account_customers_list} #{ActiveSupport::NumberHelper.number_to_currency(self.amt_auth)}. Click here to review: http://#{ENV['APPLICATION_HOST']}/transactions/#{self.tranID}/dispute?phone=#{from_customer_phone}"
        client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
        client.call(:send_sms, message: { Phone: from_customer_phone, Msg: "#{message}"})
        Rails.logger.debug "Text message sent to #{from_customer_phone}: #{message}"
      end
    end
  end
  
  def send_text_message_payment_notification
    to_customer = to_account.customer
#    from_customer_phone = from_customer.user.blank? ? from_customer.phone : from_customer.user.phone
    to_customer_phone = to_customer.user.blank? ? to_customer.phone : to_customer.user.phone
    unless to_customer_phone.blank?
      message = "#{from_account.customer_name} sent you #{ActiveSupport::NumberHelper.number_to_currency(amt_auth)}."
      client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
      client.call(:send_sms, message: { Phone: to_customer_phone, Msg: "#{message}"})
      Rails.logger.debug "Text message sent to #{to_customer_phone}: #{message}"
    end
  end
  
  def can_reverse?
    unless withdrawal? or withdrawal_all?
      return true
    else
      # tran_status of 12 means the withdrawal went through successfully, so should not be able to reverse
      if tran_status == 12
        return false
      else
        return true
      end
    end
  end
  
  def to_customer_id
    self.ToCustID
  end
  
  def to_customer
    Customer.find(self.ToCustID)
  end
  
  def from_customer_id
    self.FromCustID
  end
  
  def from_customer
    Customer.find(self.FromCustID)
  end
  
  #############################
  #     Class Methods         #
  #############################
  
  def self.ezcash_payment_transaction_web_service_call(from_account_id, to_account_id, amount, note, from_customer_id, to_customer_id, user_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:ez_cash_txn, message: { FromActID: from_account_id, ToActID: to_account_id, Amount: amount, Note: note, FromCustID: from_customer_id, ToCustID: to_customer_id, user_id: user_id})
    Rails.logger.debug "ezcash_payment_transaction_web_service_call esponse body: #{response.body}"
    unless response.body[:ez_cash_txn_response].blank? or response.body[:ez_cash_txn_response][:return].blank?
#      return response.body[:ez_cash_txn_response][:return]
      return response.body[:ez_cash_txn_response]
    else
      return nil
    end
  end
  
  def self.ezcash_event_payment_transaction_web_service_call(event_id, from_account_id, to_account_id, amount, note, from_customer_id, to_customer_id, user_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:ez_cash_txn, message: { EventID: event_id, FromActID: from_account_id, ToActID: to_account_id, Amount: amount, Note: note, FromCustID: from_customer_id, ToCustID: to_customer_id, user_id: user_id})
    Rails.logger.debug "ezcash_event_payment_transaction_web_service_call response body: #{response.body}"
    unless response.body[:ez_cash_txn_response].blank? or response.body[:ez_cash_txn_response][:return].blank?
#      return response.body[:ez_cash_txn_response][:return]
      return response.body[:ez_cash_txn_response]
    else
      return nil
    end
  end
  
  def self.ezcash_get_barcode_png_web_service_call(customer_id, company_number, scale)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:get_customer_barcode_png, message: { CustomerID: customer_id, CompanyNumber: company_number, Scale: scale})
    
    Rails.logger.debug "Response body: #{response.body}"
    
    unless response.body[:get_customer_barcode_png_response].blank? or response.body[:get_customer_barcode_png_response][:return].blank?
      return response.body[:get_customer_barcode_png_response][:return]
    else
      return ""
    end
  end
  
  def self.ezcash_quick_pay_web_service_call(amount, reference_number, device_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:encode, message: { Amount: amount, PaymentNbr: reference_number, DevID: device_id, Date: Date.today.strftime('%Y%m%d')})
    Rails.logger.debug "ezcash_quick_pay_web_service_call response body: #{response.body}"
  end
  
  def self.to_csv
    require 'csv'
    attributes = %w{tranID date_time Description dev_id error_code tran_code sec_tran_code from_acct_id to_acct_id amt_req amt_auth ChpFee}
    
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |transaction|
        csv << attributes.map{ |attr| transaction.send(attr) }
      end
    end
  end
  
  def self.export_to_csv(transactions)
    require 'csv'
    attributes = %w{tranID date_time Description dev_id error_code tran_code sec_tran_code from_acct_id to_acct_id amt_req amt_auth ChpFee}
    
    CSV.generate(headers: true) do |csv|
      csv << attributes

      transactions.each do |transaction|
        csv << attributes.map{ |attr| transaction.send(attr) }
      end
    end
  end
  
end
