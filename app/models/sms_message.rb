class SmsMessage < ApplicationRecord
  
  belongs_to :user, optional: true
  belongs_to :customer, optional: true
  belongs_to :company
  
  #############################
  #     Instance Methods      #
  #############################
  
  def sent_from_company?
    unless company.twilio_number.blank?
      from == company.twilio_number.phone_number
    else
      from == ENV['FROM_PHONE_NUMBER']
    end
  end
  
  #############################
  #     Class Methods         #
  #############################
  
end
