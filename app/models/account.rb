class Account < ActiveRecord::Base
  self.primary_key = 'ActID'
  self.table_name= 'Accounts'
  
  establish_connection :ez_cash
  
  has_many :bill_payments
  belongs_to :customer, :foreign_key => "CustomerID", optional: true
  has_many :transactions, :foreign_key => :from_acct_id
  belongs_to :company, :foreign_key => "CompanyNumber"
  belongs_to :account_type, :foreign_key => "ActTypeID"
#  belongs_to :event
  has_and_belongs_to_many :events, :join_table => :accounts_events, :uniq => true
  
  attr_accessor :last_4_of_pan
  
  attr_accessor :cc_charge_amount
  attr_accessor :cc_number
  attr_accessor :cc_expiration
  attr_accessor :cc_cvc
  
  scope :debit, -> { where(ActTypeID: 6) }
  scope :customer_primary, -> { where(AbleToDelete: [0,nil]) }
  
  scope :can_be_pulled_by_search, -> { joins(:account_type).where('AccountTypes.CanBePulledBySearch = ?', 1) }
  scope :can_be_pulled_by_scan, -> { joins(:account_type).where('AccountTypes.CanBePulledByScan = ?', 1) }
  
#  validates :ActNbr, confirmation: true
#  validates :ActNbr_confirmation, presence: true
#  validates :MinBalance, numericality: { :greater_than_or_equal_to => 0 }
#  validates :MinBalance, numericality: true
  validate :maintain_balance_not_less_than_minimum_maintain_balance, on: :update
  validate :credit_card_fields_filled

  before_save :encrypt_bank_account_number
  before_save :encrypt_bank_routing_number
  
  before_save :check_for_funding_payment
  before_create :set_maintained_balance
  
  #############################
  #     Instance Methods      #
  #############################
  
#  def customer
#    Customer.find(self.CustomerID)
#  end

#  def company
#    customer.company unless customer.blank?
#  end

  def customer_user_name_and_registration_source
    unless customer.blank?
      unless customer.Registration_Source.blank?
        "#{customer.Registration_Source} #{customer.full_name}"
      else
        customer.full_name
      end
    else
      company.name
    end
  end
  
  def customer_user_name
    unless customer.blank?
      unless customer.user.blank?
        customer.user.full_name
      else
        customer.full_name
      end
    else
      company.name
    end
  end
  
  def customer_user_role
    unless customer.user.blank?
      customer.user.role
    else
      customer.type
    end
  end
  
  def customer_name_and_events
    return "#{customer_user_name} (#{events.blank? ? 'No events' : events.map(&:title).join(', ')})"
  end
  
  def transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number) + Transaction.where(to_acct_id: decrypted_account_number)
    transactions = Transaction.where(from_acct_id: id) + Transaction.where(to_acct_id: id)
    return transactions
  end
  
  def check_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'CHK') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'CHK')
#    transactions = Transaction.where(from_acct_id: id, tran_code: 'CHK') + Transaction.where(to_acct_id: id, tran_code: 'CHK')
    transactions = Transaction.where(from_acct_id: id, tran_code: ['CHK', 'CHK '], sec_tran_code: ['TFR', 'TFR ']).order("date_time DESC") + Transaction.where(to_acct_id: id, tran_code: ['CHK', 'CHK '], sec_tran_code: ['TFR', 'TFR ']).order("date_time DESC")
    
    return transactions
  end
  
  def check_payment_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'CHKP') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'CHKP')
    transactions = Transaction.where(from_acct_id: id, tran_code: 'CHKP') + Transaction.where(to_acct_id: id, tran_code: 'CHKP')
    return transactions
  end
  
  def put_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'PUT') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'PUT')
    transactions = Transaction.where(from_acct_id: id, tran_code: 'PUT') + Transaction.where(to_acct_id: id, tran_code: 'PUT')
    return transactions
  end
  
  def withdrawal_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'WDL') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'WDL')
    transactions = Transaction.where(from_acct_id: id, tran_code: 'WDL') + Transaction.where(to_acct_id: id, tran_code: 'WDL')
    return transactions
  end
  
  def withdrawal_all_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'WDL') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'WDL')
    transactions = Transaction.where(from_acct_id: id, tran_code: 'ALL').order("date_time DESC") + Transaction.where(to_acct_id: id, tran_code: 'ALL').order("date_time DESC")
    return transactions
  end
  
  def withdrawals
    withdrawal_transactions + withdrawal_all_transactions
  end
  
  def credit_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'CRED') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'CRED')
    transactions = Transaction.where(from_acct_id: id, tran_code: 'CRED') + Transaction.where(to_acct_id: id, tran_code: 'CRED')
    return transactions
  end
  
  def one_sided_credit_transactions
    transactions = Transaction.where(from_acct_id: id, tran_code: 'DEP ', sec_tran_code: 'REFD') + Transaction.where(to_acct_id: id, tran_code: 'DEP ', sec_tran_code: 'REFD')
    return transactions
  end
  
  def cut_transactions
    transactions = one_sided_credit_transactions.select{|transaction| ( (not transaction.credit_transaction_for_transfer?) and (transaction.amt_req >= 0) )}
    return transactions
  end
  
  def transfer_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'CASH', sec_tran_code: 'TFR') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'CASH', sec_tran_code: 'TFR')
    transactions = Transaction.where(from_acct_id: id, tran_code: 'CASH', sec_tran_code: 'TFR') + Transaction.where(to_acct_id: id, tran_code: 'CASH', sec_tran_code: 'TFR')
    return transactions
  end
  
  def wire_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'CARD', sec_tran_code: 'TFR') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'CARD', sec_tran_code: 'TFR')
    transactions = Transaction.where(from_acct_id: id, tran_code: 'CARD', sec_tran_code: ['TFR', 'TFR ']).order("date_time DESC") + Transaction.where(to_acct_id: id, tran_code: 'CARD', sec_tran_code: ['TFR', 'TFR ']).order("date_time DESC")
    return transactions
  end
  
  def successful_wire_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'CARD', sec_tran_code: 'TFR') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'CARD', sec_tran_code: 'TFR')
    transactions = Transaction.where(from_acct_id: id, tran_code: 'CARD', sec_tran_code: ['TFR', 'TFR '], error_code: 0) + Transaction.where(to_acct_id: id, tran_code: 'CARD', sec_tran_code: ['TFR', 'TFR '], error_code: 0)
    return transactions
  end
  
  def purchase_transactions
#    transactions = Transaction.where(from_acct_id: decrypted_account_number, tran_code: 'POS', sec_tran_code: 'TFR') + Transaction.where(to_acct_id: decrypted_account_number, tran_code: 'POS', sec_tran_code: 'TFR')
    transactions = Transaction.where(from_acct_id: id, tran_code: 'POS', sec_tran_code: 'TFR') + Transaction.where(to_acct_id: id, tran_code: 'POS', sec_tran_code: 'TFR')
    return transactions
  end
  
  def fund_transfer_transactions
    transactions = Transaction.where(from_acct_id: id, tran_code: 'FUND', sec_tran_code: 'TFR') + Transaction.where(to_acct_id: id, tran_code: 'FUND', sec_tran_code: 'TFR')
    return transactions
  end
  
  def displayable_transactions
    check_transactions + check_payment_transactions + put_transactions + withdrawal_transactions + withdrawal_all_transactions + credit_transactions + fund_transfer_transactions + transfer_transactions + wire_transactions + purchase_transactions
  end
  
  def account_number_with_leading_zeros
    decrypted_account_number.rjust(18, '0')
  end
  
  def account_id_with_leading_zeros
    id.to_s.rjust(18, '0')
  end
  
  def decrypted_account_number
    decoded_acctnbr = Base64.decode64(self.ActNbr).unpack("H*").first
    Decrypt.decryption(decoded_acctnbr)
  end
  
  def decrypted_bank_account_number
    decoded_acctnbr = Base64.decode64(self.BankActNbr).unpack("H*").first
    Decrypt.decryption(decoded_acctnbr)
  end
  
  def decrypted_bank_routing_number
    decoded_acctnbr = Base64.decode64(self.RoutingNbr).unpack("H*").first
    Decrypt.decryption(decoded_acctnbr)
  end
  
  def standby_auth
    StandbyAuth.find_by_account_nbr(account_number_with_leading_zeros)
  end
  
  def balance
    self.Balance
  end
  
  def minimum_balance
    self.MinBalance
  end
  
  def current_balance
    self.Balance
  end
  
#  def available_balance
#    self.Balance
#  end
  
  def available_balance
    # If the account minimum balance is nil, set to zero
    unless self.MinBalance.blank? or self.MinBalance.zero? or self.MinBalance > self.Balance
      account_minimum_balance = self.MinBalance
      account_balance = self.Balance - account_minimum_balance
    else
      account_balance = 0
    end
    # The account available balance is the balance minus the minimum balance
    
    return account_balance
  end
  
  def entity
    Entity.find_by_EntityID(self.EntityID)
  end
  
  def entity_name
    entity.EntityName unless entity.blank?
  end
  
  def customer_card
    CustomerCard.find_by_ActID(id)
  end
  
  def pretty_address
    "#{entity.EntityName}<br>#{entity.EntityAddressL1}<br>#{entity.EntityCity}, #{entity.EntityState} #{entity.EntityZip}".html_safe
  end
  
#  def account_type
#    AccountType.find_by_AccountTypeID(self.ActTypeID)
#  end
  
  def debit_card?
    account_type.AccountTypeDesc == "Heavy Metal Debit" unless account_type.blank?
  end
  
  def payee?
    account_type.AccountTypeDesc == "Payments" unless account_type.blank?
  end
  
  def wire?
    account_type.AccountTypeDesc == "Wires" unless account_type.blank?
  end
  
  def active?
    self.Active == 1
  end
  
  def primary?
    (customer_card.CDType == "IND" or customer_card.CDType == "IDX" or customer_card.CDType == "IDO")  unless customer_card.blank?
  end
  
  def name
    self.ButtonText
  end
  
  def last_4_of_pan
    customer_card.last_four_of_pan unless customer_card.blank?
  end
  
  def name_with_last_4
    "#{name} #{last_4_of_pan}"
  end
  
  def name_with_last_4_and_balance
    "#{name} #{last_4_of_pan} - $#{available_balance.zero? ? available_balance.round : available_balance.round(2)}"
  end
  
  def customer_name
    "#{customer.NameF} #{customer.NameL}" unless customer.blank?
  end
  
  def first_name
    customer.NameF unless customer.blank?
  end
  
  def last_name
    customer.NameL unless customer.blank?
  end
  
  def encrypt_account_number
    unless self.ActNbr.blank?
      encrypted = Decrypt.encryption(self.ActNbr) # Encrypt the account_number
      encrypted_and_encoded = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
      self.ActNbr = encrypted_and_encoded
      self.save
    end
  end
  
  def encrypt_bank_account_number
    unless self.BankActNbr.blank?
      encrypted = Decrypt.encryption(self.BankActNbr) # Encrypt the bank account number
      encrypted_and_encoded = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
      self.BankActNbr = encrypted_and_encoded
#      self.update_attribute(:BankActNbr, encrypted_and_encoded)
    end
  end
  
  def encrypt_bank_routing_number
    unless self.RoutingNbr.blank?
      encrypted = Decrypt.encryption(self.RoutingNbr) # Encrypt the bank routing number
      encrypted_and_encoded = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
      self.RoutingNbr = encrypted_and_encoded
#      self.update_attribute(:RoutingNbr, encrypted_and_encoded)
    end
  end
  
  def encrypted_bank_account_number
    unless self.BankActNbr.blank?
      encrypted = Decrypt.encryption(self.BankActNbr) # Encrypt the bank account number
      encrypted_and_encoded = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
      return encrypted_and_encoded
    end
  end
  
  def encrypted_bank_routing_number
    unless self.RoutingNbr.blank?
      encrypted = Decrypt.encryption(self.RoutingNbr) # Encrypt the bank routing number
      encrypted_and_encoded = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
      return encrypted_and_encoded
    end
  end
  
  def set_button_text
    entity = Entity.find(self.EntityID)
    if entity.present?
      self.ButtonText = entity.name 
      self.save
    end
  end
  
  def ezcash_one_sided_credit_transaction_web_service_call(amount)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:ez_cash_txn, message: { ToActID: self.ActID, Amount: amount})
    Rails.logger.debug "Response body: #{response.body}"
    if response.success?
      unless response.body[:ez_cash_txn_response].blank? or response.body[:ez_cash_txn_response][:return].to_i > 0
        return response.body[:ez_cash_txn_response][:tran_id]
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def balance
    self.Balance
  end
  
  def description
    unless account_type.blank?
      return account_type.AccountTypeDesc
    else
      return ""
    end
  end
  
  def buddies
    company.accounts.debit.where.not(CustomerID: self.CustomerID)
  end
  
  def user
    unless customer.blank?
      customer.user
    end
  end
  
  def caddy?
    unless customer.blank?
      customer.caddy?
    else
      nil
    end
  end
  
  def member?
    unless customer.blank?
      customer.member?
    else
      nil
    end
  end
  
  def anonymous?
    unless customer.blank?
      customer.anonymous?
    else
      nil
    end
  end
  
  def consumer?
    unless customer.blank?
      customer.consumer?
    else
      nil
    end
  end
  
  def vendor?
    unless customer.blank?
      customer.vendor?
    else
      nil
    end
  end
  
  def payee?
    unless customer.blank?
      customer.payee?
    else
      nil
    end
  end
  
  def type
    if caddy?
      "Caddy"
    elsif member?
      "Member"
    elsif consumer?
      "Consumer"
    elsif vendor?
      "Vendor"
    elsif payee?
      "Payee"
    elsif anonymous?
      "Anonymous"
    else
      "Unknown"
    end
  end
  
  def can_delete?
    self.AbleToDelete == 1
  end
  
  def belongs_to_expire_accounts_event?
    events.where(expire_accounts: 1).present?
  end
  
  def can_fund_by_ach?
    account_type.can_fund_by_ach?
  end
  
  def can_fund_by_cc?
    account_type.can_fund_by_cc?
  end
  
  def can_fund_by_cash?
    account_type.can_fund_by_cash?
  end
  
  def can_withdraw?
    account_type.can_withdraw?
  end
  
  def withdrawal_all?
    account_type.withdrawal_all?
  end
  
  def can_pull?
    account_type.can_pull?
  end
  
  def can_request_payment_by_search?
    account_type.can_request_payment_by_search?
  end
  
  def can_request_payment_by_scan?
    account_type.can_request_payment_by_scan?
  end
  
  def can_send_payment?
    account_type.can_send_payment?
  end
  
  def can_be_pulled_by_scan?
    account_type.can_be_pulled_by_scan?
  end
  
  def can_be_pushed_by_scan?
    account_type.can_be_pushed_by_scan?
  end
  
  def one_time_payment(amount, note, receipt_number)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:ez_cash_txn, message: { FromActID: company.transaction_account.blank? ? nil : company.transaction_account.id, ToActID: self.ActID, Amount: amount, Fee: 0, FeeActId: company.fee_account.blank? ? nil : company.fee_account.id, Note: note, ReceiptNbr: receipt_number})
    Rails.logger.debug "************** Account one_time_payment response body: #{response.body}"
    if response.success?
      unless response.body[:ez_cash_txn_response].blank? or response.body[:ez_cash_txn_response][:return].to_i > 0
        unless customer.blank? or customer.phone.blank?
          customer.send_barcode_sms_message_with_info("You've just been paid #{ActiveSupport::NumberHelper.number_to_currency(amount)} by #{company.name}! Your current balance is #{ActiveSupport::NumberHelper.number_to_currency(balance)}. Get your cash from the PaymentATM. More information at www.tranact.com")
        end
        return response.body[:ez_cash_txn_response]
      else
        return response.body[:ez_cash_txn_response]
      end
    else
      return nil
    end
  end
  
  def one_time_payment_with_no_text_message(amount, note, receipt_number)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:ez_cash_txn, message: { FromActID: company.transaction_account.blank? ? nil : company.transaction_account.id, ToActID: self.ActID, Amount: amount, Fee: 0, FeeActId: company.fee_account.blank? ? nil : company.fee_account.id, Note: note, ReceiptNbr: receipt_number, dev_id: nil})
    Rails.logger.debug "************** Account one_time_payment_with_no_text_message response body: #{response.body}"
    if response.success?
      unless response.body[:ez_cash_txn_response].blank? or response.body[:ez_cash_txn_response][:return].to_i > 0
        return response.body[:ez_cash_txn_response]
      else
        return response.body[:ez_cash_txn_response]
      end
    else
      return nil
    end
  end
  
  def withdraw_all_barcode_png
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:get_account_barcode, message: { ActID: self.ActID, Scale: 5, amount: 0})
    
    Rails.logger.debug "Account withdraw_all_barcode_png response body: #{response.body}"
    
    unless response.body[:get_customer_barcode_png_response].blank? or response.body[:get_customer_barcode_png_response][:return].blank?
      return response.body[:get_customer_barcode_png_response][:return]
    else
      return ""
    end
  end
  
  def maintained_balance
    unless self.MaintainBal.blank?
      self.MaintainBal
    else
      0
    end
  end
  
  def set_maintained_balance
    self.MaintainBal = minimum_maintain_balance
  end
  
  def minimum_maintain_balance
    unless account_type.blank? or account_type.MinMaintainBal.blank?
      account_type.MinMaintainBal
    else
      0
    end
  end
  
  def maintain_balance_not_less_than_minimum_maintain_balance
    if maintained_balance < minimum_maintain_balance
      errors.add(:maintain_balance, "cannot be less than Wallet Type minimum maintain balance ($#{minimum_maintain_balance})") 
    end
  end
  
  def check_for_funding_payment
    unless cc_charge_amount.blank? and cc_number.blank? and cc_expiration.blank? and cc_cvc.blank?
      unless not cc_charge_amount.blank? and (cc_number.blank? or cc_expiration.blank? or cc_cvc.blank?)
        self.Balance = self.Balance + cc_charge_amount.to_d
      end
    end
  end
  
  def credit_card_fields_filled
    if not cc_charge_amount.blank? and (cc_number.blank? or cc_expiration.blank? or cc_cvc.blank?)
      errors.add(:credit_card, "all fields must be filled out")
    end
  end
  
  def bank_routing_number
    self.RoutingNbr
  end
  
  def bank_account_number
    self.BankActNbr
  end
  
  #############################
  #     Class Methods         #
  #############################
  
  def self.find_by_encrypted_account_number(number)
    Account.find_by_ActNbr(number)
  end
  
  def self.find_by_decrypted_account_number(number)
    encrypted = Decrypt.encryption(number) # Encrypt the account_number
    encrypted_and_encoded = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
    Account.find_by_ActNbr(encrypted_and_encoded)
  end
  
  def self.active_accounts
    Account.where(Active: 1)
  end
  
  def self.active_payment_accounts
    Account.active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Payments") }
  end
  
  def self.active_wire_accounts
    Account.active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Wires") }
  end
  
  def self.active_money_order_accounts
    Account.active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Money Order") }
  end
  
  def self.active_payee_accounts
    Account.active_payment_accounts + Account.active_money_order_accounts
  end
  
  def self.to_csv
    require 'csv'
    attributes = %w{first_name last_name balance}
    
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |account|
        csv << attributes.map{ |attr| account.send(attr) }
      end
    end
  end
  
end
