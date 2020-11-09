class PaymentBatch < ActiveRecord::Base
  self.primary_key = 'BatchNbr'
  self.table_name= 'PaymentBatches'
  establish_connection :ez_cash
  
  require 'csv'
  
  scope :processed, -> { where(Processed: 1) }
  scope :unprocessed, -> { where(Processed: [0, nil]) }
  scope :check, -> { where(IsCheckBatch: 1) }
  scope :cash, -> { where(IsCheckBatch: [0, nil]) }
  
  has_many :payments, :foreign_key => "BatchNbr"
  belongs_to :company, :foreign_key => "CompanyNbr"
  
  validates :CSVFile, presence: true
  
  after_commit :create_payments_from_csv, on: [:create]
  before_update :process
  after_update :send_payment_text_messages, if: :processed?
    
  #############################
  #     Instance Methods      #
  #############################
  
  def processed?
    self.Processed?
  end
  
  def create_payments_from_csv
    CSV.parse(self.CSVFile, { :headers => true }) do |row| 
      customer = Customer.find_by(CompanyNumber: self.CompanyNbr, Registration_Source: row[company.payee_number_mapping])
      if customer.blank?
        customer = Customer.find_by(CompanyNumber: self.CompanyNbr, CustomerID: row[company.payee_number_mapping])
        if customer.blank?
          customer = Customer.find_by(CompanyNumber: self.CompanyNbr, PhoneMobile: row[company.payee_number_mapping])
        end
      end
      Payment.create(CompanyNbr: self.CompanyNbr, BatchNbr: self.BatchNbr, ReferenceNbr: row[company.reference_number_mapping], 
        CustomerID: customer.blank? ? nil : customer.id, PayeeNbr: row[company.payee_number_mapping], 
        PaymentAmt: row[company.payment_amount_mapping].to_f.abs, Description: row[company.description_mapping])
    end
  end
  
  def process
    client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
    begin
      response = client.call(:process_payment_batch, message: { BatchNbr: self.BatchNbr})
      if response.success?
#        Rails.logger.debug "************** payment_batch.process response body: #{response.body}"
        unless response.body[:process_payment_batch_response].blank?
          self.processed_status = response.body[:process_payment_batch_response][:return]
          return response.body[:process_payment_batch_response][:return]
        end
      end
    rescue Savon::SOAPFault => error
      raise ActiveRecord::Rollback
      Rails.logger.debug error.http.code
      return error.http.code
    rescue Savon::HTTPError => error
      raise ActiveRecord::Rollback
      Rails.logger.debug error.http.code
      return error.http.code
    end
  end
  
  def send_payment_text_messages
    payments.each do |payment|
      if payment.processed?
        customer = payment.customer
        unless customer.blank?
#          payment.customer.generate_barcode_access_string 
#          payment.send_customer_text_message_payment_link
#          customer.send_barcode_sms_message
          customer.send_barcode_sms_message_with_info("You've just been paid #{ActiveSupport::NumberHelper.number_to_currency(payment.PaymentAmt)} by #{customer.company.name}! Your current balance is #{ActiveSupport::NumberHelper.number_to_currency(customer.balance)}. Get your cash from the PaymentATM. More information at www.tranact.com")
        end
      end
    end
  end
  
  def check?
    self.IsCheckBatch?
  end
  
  def cash?
    not check?
  end
  
  #############################
  #     Class Methods         #
  #############################
  
end