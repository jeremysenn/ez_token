class Company < ActiveRecord::Base
  self.primary_key = 'CompanyNumber'
  self.table_name= 'Companies'
  
  establish_connection :ez_cash
  
  has_many :users
#  has_many :customers, :foreign_key => "CompanyNumber" 
  has_many :accounts, :foreign_key => "CompanyNumber" 
  has_many :customers, -> { distinct }, :through => :accounts
  has_many :account_types, :foreign_key => "CompanyNumber" 
  has_many :sms_messages
  has_many :payment_batches, :foreign_key => "CompanyNbr"
  has_many :payments, :foreign_key => "CompanyNbr"
  has_one :company_act_default_min_bal, :foreign_key => "CompanyNumber"
  has_many :devices, :foreign_key => "CompanyNbr"
  has_many :transactions, :foreign_key => "DevCompanyNbr"
  has_many :payment_batch_csv_mappings
  has_many :cards, through: :devices
  has_many :customer_barcodes, :foreign_key => "CompanyNumber"
  has_many :events
  has_many :contracts
  
  ### Start Virtual Attributes ###
  def transaction_fee # Getter
    transaction_fee_cents.to_d / 100 if transaction_fee_cents
  end
  
  def transaction_fee=(dollars) # Setter
    self.transaction_fee_cents = dollars.to_d * 100 if dollars.present?
  end
  ### End Virtual Attributes ###
  
  #############################
  #     Instance Methods      #
  #############################
  
  def name
    self.CompanyName
  end
  
  def account
    accounts.where(CustomerID: nil).last
  end
  
  def fee_account
#    accounts.where(CustomerID: nil, ActTypeID: 19).last
    accounts.find_by(ActID: self.FeeActID)
  end
  
  def transaction_account
#    accounts.where(CustomerID: nil, ActTypeID: 7).last
    accounts.find_by(ActID: self.TxnActID)
  end
  
  def transaction_accounts
    accounts.where(CustomerID: nil, ActTypeID: 7)
  end
  
  def transaction_and_fee_accounts
    accounts.where(CustomerID: nil, ActTypeID: [7,19])
  end
  
  def customer_accounts
#    accounts.where.not(CustomerID: nil).where(ActTypeID: 6)
#    accounts.where.not(CustomerID: nil).where(ActTypeID: 6).customer_primary.left_outer_joins(:events).where("events.expire_accounts = 0 OR events.expire_accounts IS NULL OR events.id IS NULL").joins(:customer).order("customer.NameF")
    accounts.where.not(CustomerID: nil).left_outer_joins(:events).where("events.expire_accounts = 0 OR events.expire_accounts IS NULL OR events.id IS NULL").joins(:customer).order("customer.NameF")
  end
  
  def perform_one_sided_credit_transaction(amount)
    unless account.blank?
      transaction_id = account.ezcash_one_sided_credit_transaction_web_service_call(amount) 
      Rails.logger.debug "*************** Company One-sided EZcash transaction #{transaction_id}"
      return transaction_id
    end
  end
  
  def reference_number_mapping
    mapping = payment_batch_csv_mappings.find_by(mapped_column_name: "ReferenceNbr")
    unless mapping.blank?
      return mapping.column_name
    else
      return 'ReferenceNbr'
    end
  end
  
  def payee_number_mapping
    mapping = payment_batch_csv_mappings.find_by(mapped_column_name: "PayeeNbr")
    unless mapping.blank?
      return mapping.column_name
    else
      return 'PayeeNbr'
    end
  end
  
  def first_name_mapping
    mapping = payment_batch_csv_mappings.find_by(mapped_column_name: "FirstName")
    unless mapping.blank?
      return mapping.column_name
    else
      return 'FirstName'
    end
  end
  
  def last_name_mapping
    mapping = payment_batch_csv_mappings.find_by(mapped_column_name: "LastName")
    unless mapping.blank?
      return mapping.column_name
    else
      return 'LastName'
    end
  end
  
  def payment_amount_mapping
    mapping = payment_batch_csv_mappings.find_by(mapped_column_name: "PaymentAmt")
    unless mapping.blank?
      return mapping.column_name
    else
      return 'PaymentAmt'
    end
  end
  
  def description_mapping
    mapping = payment_batch_csv_mappings.find_by(mapped_column_name: "Description")
    unless mapping.blank?
      return mapping.column_name
    else
      return 'Description'
    end
  end
  
  def payment_batch_csv_columns
    ["ReferenceNbr", "PayeeNbr", "FirstName", "LastName", "PaymentAmt", "Description"]
  end
  
  def remaining_payment_batch_csv_mappings
    custom_mappings = payment_batch_csv_mappings.map(&:mapped_column_name)
    return payment_batch_csv_columns - custom_mappings
  end
  
  def payment_batch_csv_template
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << [reference_number_mapping, payee_number_mapping, first_name_mapping, last_name_mapping, payment_amount_mapping, description_mapping]
      csv << ['', '', '', '', '', '']
      csv << ['', '', '', '', '', '']
      csv << ['', '', '', '', '', '']
      csv << ['', '', '', '', '', '']
      csv << ['', '', '', '', '', '']
    end
  end
  
#  def customers_by_user_role(user)
#    if user.event_admin?
#      Customer.joins(:accounts).where("accounts.CompanyNumber = ?", self.CompanyNumber)
#    else
#      Customer.where(CompanyNumber: self.CompanyNumber)
#    end
#  end
#  
#  def all_customers
#    Customer.where(CompanyNumber: self.CompanyNumber)
#  end

  def quick_pay_account_type
    AccountType.find_by(AccountTypeID: self.quick_pay_account_type_id)
  end
  
  def allowed_to_quick_pay?
    self.can_quick_pay? and not self.quick_pay_account_type.blank?
  end
  
  #############################
  #     Class Methods         #
  #############################
  
end
