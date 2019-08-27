class Customer < ActiveRecord::Base
  self.primary_key = 'CustomerID'
  self.table_name= 'Customer'
  
  establish_connection :ez_cash
  
  mount_uploader :avatar, AvatarUploader
  
  belongs_to :company, :foreign_key => "CompanyNumber"
  has_many :sms_messages
  
#  has_one :account, :foreign_key => "CustomerID"
  has_many :accounts, :foreign_key => "CustomerID", inverse_of: :customer, dependent: :destroy
  has_many :transactions, :through => :account
  has_one :user
  has_many :sms_messages
  has_many :payments, :foreign_key => "CustomerID"
  has_many :customer_barcodes, :foreign_key => "CustomerID"
  belongs_to :group, :foreign_key => "GroupID"
  has_many :events, through: :accounts
  
  scope :payees, -> { where(GroupID: 18) }
  scope :vendor, -> { where(GroupID: 17) }
  scope :consumer, -> { where(GroupID: 16) }
  scope :anonymous, -> { where(GroupID: 15) }
  scope :members, -> { where(GroupID: 14) }
  scope :caddies, -> { where(GroupID: 13) }
  scope :active, -> { where(Active: true) }
  scope :not_anonymous, -> { where.not(GroupID: 15) }
  
  # Virtual Attributes
  attr_accessor :create_payee_user_flag
  attr_accessor :create_basic_user_flag
  
  accepts_nested_attributes_for :accounts, allow_destroy: true
#  accepts_nested_attributes_for :events
  
#  validates :NameF, :NameL, presence: true
#  validates :PhoneMobile, uniqueness: {allow_blank: true} #uniqueness: true, presence: true
  validates :PhoneMobile, uniqueness: {allow_blank: true}
  validates :Email, uniqueness: {allow_blank: true}
  validates :Registration_Source, uniqueness: {allow_blank: true} #, presence: true
#  validates :PhoneMobile, presence: true
#  validates_uniqueness_of :Email
#  validates_uniqueness_of :PhoneMobile
  validates :SSN, format: { with: /\A(?!219099999|078051120)(?!666|000|9\d{2})\d{3}(?!00)\d{2}(?!0{4})\d{4}\z/, message: "please enter a valid Social Security Number"}, :allow_blank => true, :if => :SSN_changed?

  before_create :format_phone_mobile_before_create
  before_update :format_phone_mobile_before_update
  after_commit :create_payee_user, on: [:create], if: :need_to_create_payee_user?
  after_commit :create_caddy_user, on: [:create], if: :need_to_create_caddy_user?
  after_commit :create_member_user, on: [:create], if: :need_to_create_member_user?
  before_create :generate_barcode_access_string
  after_update :create_payee_user, if: :need_to_create_payee_user?
  after_update :create_basic_user, if: :need_to_create_basic_user?
  after_update_commit :update_portal_user_phone, if: :phone_changed?, unless: Proc.new { |customer| customer.user.blank?}
  before_save :encrypt_ssn, if: :SSN_changed?
      
  #############################
  #     Instance Methods      #
  #############################
  
#  def account
#    accounts.first
#  end
  
  def active_accounts
    Account.where(CustomerID: id, active: true)
  end
  
  def active_checking_accounts
    active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Checking") }
  end
  
  def active_payment_accounts
    active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Payments") }
  end
  
  def active_wire_accounts
    active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Wires") }
  end
  
  def active_money_order_accounts
    active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Money Order") }
  end
  
  def active_heavy_metal_debit_card_accounts
    active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Heavy Metal Debit") }
  end
  
  def heavy_metal_debit_card_accounts
    accounts.select { |a| (a.account_type.AccountTypeDesc == "Heavy Metal Debit") }
  end
  
  def heavy_metal_debit_card_accounts_and_active_wire_accounts
    heavy_metal_debit_card_accounts + active_wire_accounts
  end
  
  def active_heavy_metal_debit_card_accounts_and_active_wire_accounts
    active_heavy_metal_debit_card_accounts + active_wire_accounts
  end
  
  def active_debit_card_accounts
    active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Debit Card") }
  end
  
  def active_funding_bank_account_accounts
    active_accounts.select { |a| (a.account_type.AccountTypeDesc == "Funding Bank Account") }
  end
  
  def active_payee_accounts
    active_payment_accounts + active_money_order_accounts
  end
  
  def active_payee_accounts_and_active_wire_accounts
    active_payee_accounts + active_wire_accounts
  end
  
  def primary_account
    active_accounts.select { |a| (a.primary?) }.first
  end
  
  # Array of account numbers
  def account_numbers
    accounts.map{ |a| a.account_number_with_leading_zeros }
  end
  
  def displayable_transactions
    transactions = []
    heavy_metal_debit_card_accounts.each do |account|
      transactions = transactions + account.displayable_transactions
    end
    return transactions
  end
  
  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end
  
  def encrypt_password(pass)
#    BCrypt::Engine.hash_secret(pass, password_salt)
#    Digest::SHA1.hexdigest(pass + user_salt).upcase
    Digest::SHA1.hexdigest(user_salt + pass).upcase
  end
  
  ### Start AES Decryption Methods ###
  def decrypted_ssn
    decoded_ssn = Base64.decode64(self.SSN).unpack("H*").first
    Decrypt.decryption(decoded_ssn)
  end
  
  def decrypted_answer_1
    unless self.Answer1.blank?
      decoded_answer_1 = Base64.decode64(self.Answer1).unpack("H*").first
      Decrypt.decryption(decoded_answer_1)
    end
  end
  
  def decrypted_answer_2
    unless self.Answer2.blank?
      decoded_answer_2 = Base64.decode64(self.Answer2).unpack("H*").first
      Decrypt.decryption(decoded_answer_2)
    end
  end
  
  def decrypted_answer_3
    unless self.Answer3.blank?
      decoded_answer_3 = Base64.decode64(self.Answer3).unpack("H*").first
      Decrypt.decryption(decoded_answer_3)
    end
  end
  ### End AES Decryption Methods ###
  
  def mobile_bill_payments
    BillPayment.where(customer_id: id)
  end
  
  def total_balance_available
    total = 0
    active_heavy_metal_debit_card_accounts.each do |account|
      total = total + account.available_balance
    end
    return total
  end
  
  def primary_balance_available
    primary_account.Balance
#    primary_account.available_balance
  end
  
  def balance
    account.Balance
  end
  
  def lang_obj_text_1
    LangObjText.find_by_LangObjID_and_LangID(self.LangObjID1, self.LangID)
  end
  
  def lang_obj_text_2
    LangObjText.find_by_LangObjID_and_LangID(self.LangObjID2, self.LangID)
  end
  
  def lang_obj_text_3
    LangObjText.find_by_LangObjID_and_LangID(self.LangObjID3, self.LangID)
  end
  
  def security_question_1
    lang_obj_text_1.LangObjText unless lang_obj_text_1.blank?
  end
  
  def security_question_2
    lang_obj_text_2.LangObjText unless lang_obj_text_2.blank?
  end
  
  def security_question_3
    lang_obj_text_3.LangObjText unless lang_obj_text_3.blank?
  end
  
  # All the possible security question lang_obj_text's
  def all_lang_obj_text_questions
    LangObjText.where(LangObjID: [8572,8573,8574,8575,9683,9684,9685,9686,9687,9688], LangID: self.LangID)
  end
  
  def custom_question_1?
    lang_obj_text_1.LangObjID == 9688 unless lang_obj_text_1.blank?
  end
  
  def custom_question_2?
    lang_obj_text_2.LangObjID == 9688 unless lang_obj_text_2.blank?
  end
  
  def custom_question_3?
    lang_obj_text_3.LangObjID == 9688 unless lang_obj_text_3.blank?
  end
  
  def needs_to_update_profile?
    self.IsTempUserName == true or self.IsTempPassword == true or user_name.blank? or pwd_needs_change == 1
  end
  
  ### Start custom validations ###
  def questions_not_duplicated
    errors.add(:LangObjID2, "Selected questions should not be duplicated") if security_question_1 == security_question_2
    errors.add(:LangObjID3, "Selected questions should not be duplicated") if security_question_1 == security_question_3
    errors.add(:LangObjID3, "Selected questions should not be duplicated") if security_question_2 == security_question_3
  end
  ### End custom validations ###
  
  def send_forgot_password_message
    phone = self.PhoneMobile || " "
    email = self.Email || " "
#    random_password = ('0'..'z').to_a.shuffle.first(8).join
    random_password = SecureRandom.hex(4)
#    encrypted_random_password = Digest::SHA1.hexdigest(random_password + user_salt).upcase
    encrypted_random_password = Digest::SHA1.hexdigest(user_salt + random_password).upcase
    subject = "Forgot Password"
    message = "Your temporary password is #{random_password} Please use this and your username to login at www.personalfinancesystem.com"
    
    ### Just send sms text message ###
    TgsOutMsg.create(msg_type: 1, msg_body: message, to_email: email, to_phone: phone, 
      email_subject: " ", processed: false, err_flag: false, seq_nbr: 0) if self.MessageSMS == 1 and self.MessageEmail == 0 and not phone.blank?
    
    ### Just send email message ###
    TgsOutMsg.create(msg_type: 2, msg_body: message, to_email: email, to_phone: phone, 
      email_subject: subject, processed: false, err_flag: false, seq_nbr: 0) if self.MessageSMS == 0 and self.MessageEmail == 1 and not email.blank?
    
    ### Send both sms text and email message ###
    TgsOutMsg.create(msg_type: 3, msg_body: message, to_email: email, to_phone: phone, 
      email_subject: subject, processed: false, err_flag: false, seq_nbr: 0) if self.MessageSMS == 1 and self.MessageEmail == 1 and not email.blank? and not phone.blank?
    
    self.update_attributes(pwd_hash: encrypted_random_password, IsTempPassword: true, pwd_needs_change: 1, Answer1: decrypted_answer_1, Answer2: decrypted_answer_2, Answer3: decrypted_answer_3 )
  end
  
  def can_create_bill_payments?
    group.IsViewPayeeSection == true
  end
  
  def entities
    Entity.where(OwningCustomerID: id)
  end
  
  def is_customer_service_rep?
    self.GroupID < 5
  end
  
  def cust_pics
    cust_pics = CustPic.where(cust_nbr: id.to_s)
    unless cust_pics.blank?
      return cust_pics
    else
      return []
    end
  end
  
  def images
    images = Image.where(custid: id)
    unless images.blank?
      return images
    else
      return []
    end
  end
  
  def cust_pics_without_drivers_license
    cust_pics.where.not(event_code: ["DL", "DLF"]) unless cust_pics.blank?
  end
  
  def drivers_license_cust_pic
    cust_pics.where(event_code: ["DL", "DLF"]).last unless cust_pics.blank?
  end
  
  def customer_cards
    CustomerCard.where(CustomerID: id)
  end
  
  def first_name
    self.NameF
  end
  
  def last_name
    self.NameL
  end
  
  def full_name
    "#{self.NameF} #{self.NameL} #{self.NameS}"
  end
  
  def full_name_by_last_name
    "#{self.NameL}, #{self.NameF} "
  end
  
  def full_name_with_member_number
    "#{self.NameF} #{self.NameL} #{member_number}"
  end
  
  def user_name
    unless user.blank?
      user.full_name
    else
      full_name
    end
  end
  
  def identity
    if full_name.blank? and phone.blank?
      'N/A'
    else
      if full_name.blank?
        phone
      else
        full_name
      end
    end
  end
  
  def email
    self.Email
  end
  
  def company_id
    self.CompanyNumber
  end
  
  def member_number
    self.Registration_Source
#    unless self.Registration_Source.blank?
#      self.Registration_Source
#    else
#      if primary?
#        account.ActNbr unless account.blank?
#      else
#        parent_customer.member_number
#      end
#    end
  end
  
  def member_extension
    self.Registration_Source_ext
  end
  
  def primary?
    self.ParentCustID.blank?
  end
  
  def parent_customer
    Customer.where(CustomerID: self.ParentCustID).first unless primary?
  end
  
  def primary_member
    unless primary?
      parent_customer
    else
      self
    end
  end
  
  def active?
    self.Active?
  end
  
  def inactive?
    not active?
  end
  
  def match_account_active_status
    accounts.each do |account|
      if self.Active == account.Active
        nil
      else
        account.update_attribute(:Active, self.Active)
      end
    end
#    unless account.blank?
#      if self.Active == account.Active
#        nil
#      else
#        account.update_attribute(:Active, self.Active)
#      end
#    end
  end
  
  def phone
    self.PhoneMobile
  end
  
  def twilio_formated_phone_number
    "+1#{phone.gsub(/([-() ])/, '')}" if phone
  end
  
#  def account_id
#    if primary?
#      account.id
#    else
#      parent_customer.account.id
#    end
#  end
  
  def clear_account_balance
    if balance < 0 # Make sure it's a negative value
      # Perform one-sided transaction for company account (credit the customer's balance as a positive
      company.perform_one_sided_credit_transaction(-balance)
      
      # Credit customers account
      client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
      response = client.call(:ez_cash_txn, message: { FromActID: company.account.id, ToActID: account_id, Amount: balance.abs})
      
      Rails.logger.debug "Clear customer account balance response body: #{response.body}"
      if response and response.success?
        unless response.body[:ez_cash_txn_response].blank? or response.body[:ez_cash_txn_response][:return].to_i > 0
          return true
        else
          # Reverse the one-sided transaction from the company account if customer transaction doesn't go through.
          company.perform_one_sided_credit_transaction(balance) # Credit the company account a negative value, effectively reversing it
          return nil
        end
      else
        # Reverse the one-sided transaction from the company account if customer transaction doesn't go through.
        company.perform_one_sided_credit_transaction(balance) # Credit the company account a negative value, effectively reversing it
        return nil
      end
    else
      return nil
    end
  end
  
  def credit_account(amount)
    # Perform one-sided transaction for company account (credit the customer's balance as a positive)
    company.perform_one_sided_credit_transaction(amount)

    # Credit customers account
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:ez_cash_txn, message: { FromActID: company.account.id, ToActID: account_id, Amount: amount})

    Rails.logger.debug "Credit customer account response body: #{response.body}"
    if response and response.success?
      unless response.body[:ez_cash_txn_response].blank? or response.body[:ez_cash_txn_response][:return].to_i > 0
        return true
      else
        # Reverse the one-sided transaction from the company account if customer transaction doesn't go through.
        company.perform_one_sided_credit_transaction(-amount) # Credit the company account a negative value, effectively reversing it
        return nil
      end
    else
      # Reverse the one-sided transaction from the company account if customer transaction doesn't go through.
      company.perform_one_sided_credit_transaction(-amount) # Credit the company account a negative value, effectively reversing it
      return nil
    end
  end
  
  def caddy?
    self.GroupID == 13
  end
  
  def member?
    self.GroupID == 14
  end
  
  def anonymous?
    self.GroupID == 15
  end
  
  def consumer?
    self.GroupID == 16
  end
  
  def vendor?
    self.GroupID == 17
  end
  
  def payee?
    self.GroupID == 18
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
  
  def vendor_payables_with_balance
    vendor_payables.where("Balance > ?", 0)
  end
  
  def withdrawals
    unless accounts.blank?
      accounts.first.withdrawals 
    else
      return []
    end
  end
  
  def payments
    unless accounts.blank?
      accounts.first.wire_transactions 
    else
      return []
    end
  end
  
  def successful_payments
    unless accounts.blank?
      accounts.first.successful_wire_transactions
    else
      return []
    end
  end
  
  def cashed_checks
    unless accounts.blank?
      accounts.first.check_transactions
    else
      return []
    end
  end
  
  def one_time_payment(amount, note, receipt_number, event_id, device_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:ez_cash_txn, message: { FromActID: company.transaction_account.blank? ? nil : company.transaction_account.id, ToActID: account.id, Amount: amount, Fee: 0, FeeActId: company.fee_account.blank? ? nil : company.fee_account.id, Note: note, ReceiptNbr: receipt_number, event_id: event_id, dev_id: device_id})
    Rails.logger.debug "************** Customer one_time_payment response body: #{response.body}"
    if response.success?
      unless response.body[:ez_cash_txn_response].blank? or response.body[:ez_cash_txn_response][:return].to_i > 0
        unless phone.blank?
          send_barcode_sms_message_with_info("You've just been paid #{ActiveSupport::NumberHelper.number_to_currency(amount)} by #{company.name}! Get your cash from the PaymentATM. More information at www.tranact.com")
        end
        return response.body[:ez_cash_txn_response]
      else
        return response.body[:ez_cash_txn_response]
      end
    else
      return nil
    end
  end
  
  def one_time_payment_with_no_text_message(amount, note, receipt_number, event_id, device_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:ez_cash_txn, message: { FromActID: company.transaction_account.blank? ? nil : company.transaction_account.id, ToActID: accounts.first.id, Amount: amount, Fee: 0, FeeActId: company.fee_account.blank? ? nil : company.fee_account.id, Note: note, ReceiptNbr: receipt_number, event_id: event_id, dev_id: device_id})
    Rails.logger.debug "************** Customer one_time_payment_with_no_text_message response body: #{response.body}"
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
  
  def barcode
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:get_customer_barcode, message: { CustomerID: self.CustomerID})
    Rails.logger.debug "barcode response body: #{response.body}"
    unless response.body[:get_customer_barcode_response].blank? or response.body[:get_customer_barcode_response][:return].blank?
      return response.body[:get_customer_barcode_response][:return]
    else
      return ""
    end
  end
  
  def barcode_png
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:get_customer_barcode_png, message: { CustomerID: self.CustomerID, CompanyNumber: self.CompanyNumber, Scale: 5, amount: 0})
    
    Rails.logger.debug "barcode_png response body: #{response.body}"
    
    unless response.body[:get_customer_barcode_png_response].blank? or response.body[:get_customer_barcode_png_response][:return].blank?
      return response.body[:get_customer_barcode_png_response][:return]
    else
      return ""
    end
  end
  
  def barcode_png_by_device(device_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:get_customer_barcode_png, message: {DevID: device_id, CustomerID: self.CustomerID, CompanyNumber: self.CompanyNumber, Scale: 5, amount: 0})
    
    Rails.logger.debug "barcode_png response body: #{response.body}"
    
    unless response.body[:get_customer_barcode_png_response].blank? or response.body[:get_customer_barcode_png_response][:return].blank?
      return response.body[:get_customer_barcode_png_response][:return]
    else
      return ""
    end
  end
  
  def barcode_png_by_company(company_id)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:get_customer_barcode_png, message: { CustomerID: self.CustomerID, CompanyNumber: company_id, Scale: 5, amount: 0})
    
    Rails.logger.debug "barcode_png_by_company response body: #{response.body}"
    
    unless response.body[:get_customer_barcode_png_response].blank? or response.body[:get_customer_barcode_png_response][:return].blank?
      return response.body[:get_customer_barcode_png_response][:return]
    else
      return ""
    end
  end
  
  def barcode_png_with_amount(amount)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:get_customer_barcode_png, message: { CustomerID: self.CustomerID, CompanyNumber: self.CompanyNumber, Scale: 5, amount: amount})
    
    Rails.logger.debug "barcode_png_with_amount response body: #{response.body}"
    
    unless response.body[:get_customer_barcode_png_response].blank? or response.body[:get_customer_barcode_png_response][:return].blank?
      return response.body[:get_customer_barcode_png_response][:return]
    else
      return ""
    end
  end
  
  def barcode_png_with_amount_by_company(amount, company)
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    response = client.call(:get_customer_barcode_png, message: { CustomerID: self.CustomerID, CompanyNumber: company, Scale: 5, amount: amount})
    
    Rails.logger.debug "barcode_png_with_amount_by_company response body: #{response.body}"
    
    unless response.body[:get_customer_barcode_png_response].blank? or response.body[:get_customer_barcode_png_response][:return].blank?
      return response.body[:get_customer_barcode_png_response][:return]
    else
      return ""
    end
  end
  
  def send_sms_message(message_body, user_id)
    unless phone.blank?
#      SendCaddySmsWorker.perform_async(cell_phone_number, id, self.CustomerID, self.ClubCompanyNbr, message_body)
      client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
      client.call(:send_sms, message: { Phone: phone, Msg: "#{message_body} - sent from #{company.name}"})
      SmsMessage.create(to: phone, customer_id: self.id, user_id: user_id, company_id: self.CompanyNumber, body: "#{message_body} - sent from #{company.name}")
    end
  end
  
  def twilio_send_sms_message(body, from_user_id)
    unless phone.blank?
      user = User.find(from_user_id)
      account_sid = ENV["TWILIO_ACCOUNT_SID"]
      auth_token = ENV["TWILIO_AUTH_TOKEN"]
      client = Twilio::REST::Client.new account_sid, auth_token
      from = ENV["FROM_PHONE_NUMBER"]
      begin
        message = client.messages.create(
          :from => from,
          :to => twilio_formated_phone_number,
          :body => body #,
        )
        sid = message.sid
        SmsMessage.create(sid: sid, to: twilio_formated_phone_number, from: from, customer_id: self.id, user_id: from_user_id, company_id: user.company_id, body: "#{body}")
      rescue Twilio::REST::RestError => e
        puts e.message
      end
    end
  end
  
  def send_barcode_link_sms_message
    unless phone.blank? or barcode_access_string.blank?
#      SendSmsWorker.perform_async(cell_phone_number, id, self.CustomerID, self.ClubCompanyNbr, message_body)
      payment_link = "#{Rails.application.routes.default_url_options[:host]}/customers/#{barcode_access_string}/barcode"
      message = "Get your cash from the PaymentATM by clicking this link: #{payment_link}"
      client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
      client.call(:send_sms, message: { Phone: phone, Msg: "#{message}"})
    end
  end
  
  def send_barcode_sms_message(account_id, amount)
    account = accounts.find_by(ActID: account_id)
    unless phone.blank? or account.blank?
      client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
#      client.call(:send_mms_cust_barcode, message: { CustomerID: self.CustomerID, CompanyNumber: account.CompanyNumber})
      client.call(:send_mms_cust_barcode, message: { ActID: account_id, CustomerID: self.CustomerID, CompanyNumber: account.CompanyNumber, Amount: amount})
    end
  end
  
  def send_barcode_sms_message_with_info(message)
    unless phone.blank?
      client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
      client.call(:send_mmsqr_barcode, message: { Phone: phone, Msg: message, Barcode: self.barcode})
    end
  end
  
  def generate_barcode_access_string
#    self.barcode_access_string = SecureRandom.urlsafe_base64
#    self.save
    access_string = SecureRandom.urlsafe_base64
    self.barcode_access_string = access_string
  end
  
  def need_to_create_payee_user?
    return create_payee_user_flag == "true"
  end
  
  def need_to_create_basic_user?
    return create_basic_user_flag == "true"
  end
  
  def create_payee_user
#    temporary_password = Devise.friendly_token.first(10)
#    temporary_password = SecureRandom.hex.first(6)
    temporary_password = SecureRandom.random_number(10**6).to_s
    User.create(first_name: first_name, last_name: last_name, email: email, company_id: company_id, customer_id: id, role: "payee", phone: phone,
    password: temporary_password, password_confirmation: temporary_password, temporary_password: temporary_password)
  end
  
  def create_basic_user
    temporary_password = SecureRandom.random_number(10**6).to_s
    User.create(first_name: first_name, last_name: last_name, email: email, company_id: company_id, customer_id: id, role: "basic", phone: phone,
    password: temporary_password, password_confirmation: temporary_password, temporary_password: temporary_password)
  end
  
  def need_to_create_caddy_user?
    self.GroupID == 13
  end
  
  def create_caddy_user
    temporary_password = SecureRandom.random_number(10**6).to_s
    User.create(first_name: first_name, last_name: last_name, email: email, company_id: company_id, customer_id: id, role: "caddy", phone: phone,
    password: temporary_password, password_confirmation: temporary_password, temporary_password: temporary_password)
  end
  
  def need_to_create_member_user?
    self.GroupID == 14
  end
  
  def create_member_user
    temporary_password = SecureRandom.random_number(10**6).to_s
    User.create(first_name: first_name, last_name: last_name, email: email, company_id: company_id, customer_id: id, role: "member", phone: phone,
    password: temporary_password, password_confirmation: temporary_password, temporary_password: temporary_password)
  end
  
  def phone_changed?
    saved_change_to_PhoneMobile?
  end
  
  def update_portal_user_phone
    user.update_attribute(:phone, phone)
  end
  
  def accounts_with_events
    accounts.left_outer_joins(:events).where.not(events: {id: nil})
  end
  
  def ssn
    return self.SSN
  end
  
  def encrypt_ssn
    unless self.SSN.blank?
      encrypted = Decrypt.encryption(self.SSN) # Encrypt ssn
      encrypted_and_encoded = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
      self.SSN = encrypted_and_encoded
    end
  end
  
  def decrypted_ssn
    decoded_acctnbr = Base64.decode64(self.SSN).unpack("H*").first
    Decrypt.decryption(decoded_acctnbr)
  end
  
  def last_4_decrypted_ssn
    decrypted_ssn.last(4)
  end
  
  def format_phone_mobile_before_create
    self.PhoneMobile = "#{self.PhoneMobile.gsub(/([-() ])/, '')}" if self.PhoneMobile
  end

  def format_phone_mobile_before_update
    self.PhoneMobile = "#{self.PhoneMobile.gsub(/([-() ])/, '')}" if self.PhoneMobile
  end
  
  def date_of_birth_required?
    unless accounts.blank?
      dob_accounts = accounts.select { |a| (not a.account_type.blank? and a.account_type.date_of_birth_required == 1) } 
      return dob_accounts.present?
    else
      false
    end
  end
  
  def social_security_number_required?
    unless accounts.blank?
      ssn_accounts = accounts.select { |a| (not a.account_type.blank? and a.account_type.social_security_number_required == 1) } 
      return ssn_accounts.present?
    else
      false
    end
  end
  
  def valid_social_security_number_format?
    !!(decrypted_ssn =~ /^(?!219099999|078051120)(?!666|000|9\d{2})\d{3}(?!00)\d{2}(?!0{4})\d{4}$/)
  end
 
  #############################
  #     Class Methods         #
  #############################
  
  def self.authenticate(user_name, pass)
    customer = Customer.find_by_user_name(user_name)
    return customer if customer #&& customer.pwd_hash == customer.encrypt_password(pass)
  end
  
  def self.to_csv
    require 'csv'
    attributes = %w{phone first_name last_name balance}
    
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |account|
        csv << attributes.map{ |attr| account.send(attr) }
      end
    end
  end
  
  def self.valid_social_security_number_format?(ssn_number)
    !!(ssn_number =~ /\A(?!219099999|078051120)(?!666|000|9\d{2})\d{3}(?!00)\d{2}(?!0{4})\d{4}\z/)
  end
  
  private

  def encrypt_all_security_question_answers
    unless self.Answer1.blank?
      encrypted = Decrypt.encryption(self.Answer1) # Encrypt the answer
      self.Answer1 = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
    end
    unless self.Answer2.blank?
      encrypted = Decrypt.encryption(self.Answer2) # Encrypt the answer
      self.Answer2 = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
    end
    unless self.Answer3.blank?
      encrypted = Decrypt.encryption(self.Answer3) # Encrypt the answer 
      self.Answer3 = Base64.strict_encode64(encrypted) # Base 64 encode it; strict_encode64 doesn't add the \n character on the end
    end
  end
  
  def prepare_password
    unless password.blank?
#      self.pwd_hash = Digest::SHA1.hexdigest(password + user_salt).upcase
      self.pwd_hash = Digest::SHA1.hexdigest(user_salt + password).upcase
    end
  end
  
end
