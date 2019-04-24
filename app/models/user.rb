class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :registerable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :confirmable #, :timeoutable
  
#  ROLES = %w[admin caddy_admin event_admin basic caddy member consumer payee vendor].freeze
  ROLES = %w[admin basic collaborator].freeze
       
  belongs_to :company
  belongs_to :customer, optional: true
  has_many :sms_messages
  has_many :accounts, through: :customer
  has_many :events, through: :customer
  
  serialize :device_ids, Array
  
  scope :admin, -> { where(role: "admin") }
  scope :basic, -> { where(role: "basic") }
  scope :collaborator, -> { where(role: "collaborator") }
  scope :payee, -> { where(role: "payee") }
  
#  before_create :search_for_payee_match

  before_create :format_phone_before_create
  before_update :format_phone_before_update
  before_create :search_for_customer_match
  after_create :send_confirmation_sms_message
  after_update :send_new_phone_number_confirmation_sms_message, if: :phone_changed?
  after_update :update_customer_record,
    :if => proc {|obj| obj.phone_changed? || obj.first_name_changed? ||  obj.last_name_changed? || obj.email_changed?}  
      
  validates :phone, uniqueness: true, presence: true 
  validates :email, uniqueness: {allow_blank: true}
    
  #############################
  #     Instance Methods      #
  #############################
  
  ### Don't require email - from Devise wiki ###
  def email_required?
    false
  end
  
  def will_save_change_to_email?
    false
  end
  ### End Don't require email - from Devise wiki ###
  
  ### Don't send confirmation email - from Devise wiki ###
  def send_confirmation_notification?
    false
  end
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def administrator?
    role == "admin" or role == "caddy_admin" or role == "event_admin"
  end
  
  def admin?
    role == "admin" 
  end
  
  def basic?
    role == "basic"
  end
  
  def collaborator?
    role == "collaborator"
  end
  
  def search_for_payee_match
    payee = Customer.find_by(PhoneMobile: phone)
    unless payee.blank?
      self.customer_id = payee.id
      self.role = "payee"
      self.company_id = payee.company_id
    else
      if self.role.blank?
        self.role = "consumer"
      end
    end
  end
  
  def search_for_customer_match
    customer = Customer.find_by(PhoneMobile: phone)
    unless customer.blank?
      self.customer_id = customer.id
    end
  end
  
  def send_confirmation_sms_message
    unless phone.blank? or self.confirmed?
#      SendCaddySmsWorker.perform_async(cell_phone_number, id, self.CustomerID, self.ClubCompanyNbr, message_body)
      confirmation_link = "#{Rails.application.routes.default_url_options[:host]}/users/confirmation?confirmation_token=#{confirmation_token}"
      unless temporary_password.blank?
        message = "Confirm your ezToken account by clicking the link below. Your temporary password is: #{temporary_password} #{confirmation_link}"
      else
        message = "Confirm your ezToken account by clicking the link below. #{confirmation_link}"
      end
      client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
      client.call(:send_sms, message: { Phone: phone, Msg: "#{message}"})
#      SmsMessage.create(to: phone, company_id: company_id, body: "#{message}")
    end
  end
  
  def send_new_phone_number_confirmation_sms_message
    unless phone.blank?
      confirmation_link = "#{Rails.application.routes.default_url_options[:host]}/users/confirmation?confirmation_token=#{confirmation_token}"
      message = "Confirm the change to your account by clicking the link below.  #{confirmation_link}"
      client = Savon.client(wsdl: "#{ENV['EZCASH_WSDL_URL']}")
      client.call(:send_sms, message: { Phone: phone, Msg: "#{message}"})
      self.confirmed_at = nil
      self.save
    end
  end
  
  def phone_changed?
    saved_change_to_phone?
  end
  
  def first_name_changed?
    saved_change_to_first_name?
  end
  
  def last_name_changed?
    saved_change_to_last_name?
  end
  
  def email_changed?
    saved_change_to_email?
  end
  
  def devices
#    company.devices
    if admin?
      company.devices
    elsif basic?
      company.devices.where(dev_id: device_ids)
    end
  end
  
  def qr_code
    require 'barby'
    require 'barby/barcode'
    require 'barby/barcode/qr_code'
    require 'barby/outputter/png_outputter'

    barcode = Barby::QrCode.new(customer.barcode_access_string, level: :q, size: 5)
    base64_output = Base64.encode64(barcode.to_png({ xdim: 5 }))
    "data:image/png;base64,#{base64_output}"
  end
  
  def qr_code_png
    require 'barby'
    require 'barby/barcode'
    require 'barby/barcode/qr_code'
    require 'barby/outputter/png_outputter'

    barcode = Barby::QrCode.new(customer.barcode_access_string, level: :q, size: 5)
    barcode.to_png({ xdim: 5 })
  end
  
  def set_temporary_password
    temp_pass = SecureRandom.random_number(10**6).to_s
    self.update_attributes(temporary_password: temp_pass, password: temp_pass, password_confirmation: temp_pass)
  end
  
  def create_consumer_customer_and_account_records
    customer = Customer.create(CompanyNumber: company_id, LangID: 1, Active: 1, GroupID: 16)
    Account.create(CustomerID: customer.id, CompanyNumber: company_id, Balance: 0, MinBalance: 0, ActTypeID: 6)
  end
  
  def create_event_account(event)
    unless event.join_by_sms_wallet_type.blank?
      unless events.include?(event)
        existing_company_account = accounts.find_by(ActTypeID: event.join_by_sms_wallet_type.id, CompanyNumber: event.company_id)
        if existing_company_account.blank? 
          new_account = Account.create(CustomerID: customer.id, CompanyNumber: event.company_id, Balance: 0, MinBalance: 0, ActTypeID: event.join_by_sms_wallet_type.id)
          event.accounts << new_account
          return new_account
        else
          if event.expire_accounts?
            new_account = Account.create(CustomerID: customer.id, CompanyNumber: event.company_id, Balance: 0, MinBalance: 0, ActTypeID: event.join_by_sms_wallet_type.id)
            event.accounts << new_account
            return new_account
          else
            event.accounts << existing_company_account
            return existing_company_account
          end
        end
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def twilio_formated_phone_number
    "+1#{phone.gsub(/([-() ])/, '')}" if phone
  end
  
  def send_text_message(body)
    unless phone.blank?
      account_sid = ENV["TWILIO_ACCOUNT_SID"]
      auth_token = ENV["TWILIO_AUTH_TOKEN"]
      client = Twilio::REST::Client.new account_sid, auth_token

      begin
        client.messages.create(
          :from => ENV["FROM_PHONE_NUMBER"],
          :to => twilio_formated_phone_number,
          :body => body #,
#          :media_url => "https://www.gstatic.com/webp/gallery/1.sm.jpg"
        )
      rescue Twilio::REST::RestError => e
        puts e.message
      end
    end
  end
  
  def send_media_text_message(media_url)
    unless phone.blank?
      account_sid = ENV["TWILIO_ACCOUNT_SID"]
      auth_token = ENV["TWILIO_AUTH_TOKEN"]
      client = Twilio::REST::Client.new account_sid, auth_token

      begin
        client.messages.create(
          :from => ENV["FROM_PHONE_NUMBER"],
          :to => twilio_formated_phone_number,
          :body => "",
          :media_url => media_url
        )
      rescue Twilio::REST::RestError => e
        puts e.message
      end
    end
  end
  
  def update_customer_record
    unless customer.blank?
      customer.update_attributes(PhoneMobile: phone, NameF: first_name, NameL: last_name, Email: email)
    end
  end
  
  def can_view_events?
    admin? or view_events?
  end
  
  def can_edit_events?
    admin? or edit_events?
  end
  
  def can_view_accounts?
    admin? or view_accounts?
  end
  
  def can_edit_accounts?
    admin? or edit_accounts?
  end
  
  def can_view_wallet_types?
    admin? or view_wallet_types?
  end
  
  def can_edit_wallet_types?
    admin? or edit_wallet_types?
  end
  
  def can_view_users?
    admin? or view_users?
  end
  
  def can_edit_users?
    admin? or edit_users?
  end
  
  def can_view_atms?
    admin? or view_atms?
  end
  
  def can_view_atms?
    admin? or view_atms?
  end
  
  def can_quick_pay_customers?
    admin? or can_quick_pay?
  end
  
  def format_phone_before_create
    self.phone = "#{phone.gsub(/([-() ])/, '')}" if phone
  end

  def format_phone_before_update
    self.phone = "#{phone.gsub(/([-() ])/, '')}" if phone
  end
  
  def plain_phone # Remove the +1 in front of the number
    phone.gsub(/\+1/, '') unless phone.blank?
  end
  
end
