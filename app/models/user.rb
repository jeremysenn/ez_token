class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :registerable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :confirmable #, :timeoutable
  
#  ROLES = %w[admin caddy_admin event_admin basic caddy member consumer payee vendor].freeze
  ROLES = %w[admin basic].freeze
       
  belongs_to :company
  belongs_to :customer, optional: true
  has_many :sms_messages
  has_many :accounts, through: :customer
  has_many :events, through: :customer
  
  serialize :device_ids, Array
  
  scope :admin, -> { where(role: "admin") }
  scope :caddy_admin, -> { where(role: "caddy_admin") }
  scope :event_admin, -> { where(role: "event_admin") }
  scope :basic, -> { where(role: "basic") }
  scope :caddy, -> { where(role: "caddy") }
  scope :member, -> { where(role: "member") }
  scope :consumer, -> { where(role: "consumer") }
  scope :payee, -> { where(role: "payee") }
  scope :vendor, -> { where(role: "vendor") }
  
#  before_create :search_for_payee_match
  after_create :send_confirmation_sms_message
  after_update :send_new_phone_number_confirmation_sms_message, if: :phone_changed?
  
  validates :phone, uniqueness: true, presence: true  
    
  #############################
  #     Instance Methods      #
  #############################
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def administrator?
    role == "admin" or role == "caddy_admin" or role == "event_admin"
  end
  
  def admin?
    role == "admin" #or role == "caddy_admin" or role == "event_admin"
  end
  
  def caddy_admin?
    role == "caddy_admin"
  end
  
  def event_admin?
    role == "event_admin"
  end
  
  def basic?
    role == "basic"
  end
  
  def caddy?
    role == "caddy"
  end
  
  def member?
    role == "member"
  end
  
  def consumer?
    role == "consumer"
  end
  
  def payee?
    role == "payee"
  end
  
  def vendor?
    role == "vendor"
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
  
  def send_confirmation_sms_message
    unless phone.blank?
#      SendCaddySmsWorker.perform_async(cell_phone_number, id, self.CustomerID, self.ClubCompanyNbr, message_body)
      confirmation_link = "#{Rails.application.routes.default_url_options[:host]}/users/confirmation?confirmation_token=#{confirmation_token}"
      unless temporary_password.blank?
        message = "Confirm your account by clicking the link below. Your temporary password is: #{temporary_password} #{confirmation_link}"
      else
        message = "Confirm your account by clicking the link below. #{confirmation_link}"
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
    unless events.include?(event)
      existing_company_account = accounts.find_by(CompanyNumber: event.company_id)
      if existing_company_account.blank? 
        new_account = Account.create(CustomerID: customer.id, CompanyNumber: event.company_id, Balance: 0, MinBalance: 0, ActTypeID: 6)
        event.accounts << new_account
      else
        if event.expire_accounts?
          new_account = Account.create(CustomerID: customer.id, CompanyNumber: event.company_id, Balance: 0, MinBalance: 0, ActTypeID: 6)
          event.accounts << new_account
        else
          event.accounts << existing_company_account
        end
      end
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
  
end
