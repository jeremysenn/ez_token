class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :registerable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :confirmable #, :timeoutable
  
  ROLES = %w[admin basic caddy consumer payee vendor].freeze
       
  belongs_to :company
  belongs_to :customer, optional: true
  has_many :sms_messages
  
  serialize :device_ids, Array
  
  scope :admin, -> { where(role: "admin") }
  scope :basic, -> { where(role: "basic") }
  scope :caddy, -> { where(role: "caddy") }
  scope :consumer, -> { where(role: "consumer") }
  scope :payee, -> { where(role: "payee") }
  scope :vendor, -> { where(role: "vendor") }
  
  before_create :search_for_payee_match
  after_create :send_confirmation_sms_message
  after_update :send_new_phone_number_confirmation_sms_message, if: :phone_changed?
  
  validates :phone, uniqueness: true, presence: true  
    
  #############################
  #     Instance Methods      #
  #############################
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def admin?
    role == "admin"
  end
  
  def basic?
    role == "basic"
  end
  
  def caddy?
    role == "caddy"
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
  
end
