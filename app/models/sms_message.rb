class SmsMessage < ApplicationRecord
  
  belongs_to :user, optional: true
  belongs_to :customer, optional: true
  belongs_to :company
  
#  after_create_commit { SmsMessagseBroadcastJob.perform_later self.id }
  after_create_commit :broadcast_to_channels
  
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
  
  def broadcast_to_channels
    SmsMessageChannel.broadcast_to self.customer, "#{self.broadcast_html}"
    SmsMessageBodyChannel.broadcast_to self.customer, self.body
#    SmsMessageChannel.broadcast_to self.customer, self.body
  end
  
  def broadcast_html
    ApplicationController.render(
      partial: 'sms_messages/sms_message_for_channel',
      locals: { sms_message: self }
    )
  end
  
  #############################
  #     Class Methods         #
  #############################
  
end
