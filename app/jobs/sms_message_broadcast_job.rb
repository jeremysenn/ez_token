class SmsMessageBroadcastJob < ApplicationJob
  queue_as :default

  def perform(sms_message_id)
    sms_message = SmsMessage.find(sms_message_id)
    
    ActionCable.server.broadcast "customer_#{sms_message.customer_id}_sms_message_channel", {message: render_sms_message(sms_message), customer_id: sms_message.customer_id}
#    ActionCable.server.broadcast 'media_channel', message: 'hello out there'
  end
  
  private

  def render_sms_message(sms_message)
    SmsMessagesController.render partial: 'sms_messages/sms_message', locals: {sms_message: sms_message}
  end
  
end