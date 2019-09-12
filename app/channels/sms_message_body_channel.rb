# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class SmsMessageBodyChannel < ApplicationCable::Channel
  def subscribed
    customer = Customer.find(params['customer'])
    stream_for customer
    
    # or
    # stream_from "customer_#{params[:customer]}"
     
#    If use stream_from: we manually define the name of the stream and later on, when we want to broadcast to the stream, we have to use: ActionCable.server.broadcast("customer_#{customer_id}", data).
    
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

#  def speak(data)
##    ActionCable.server.broadcast "sms_message_channel", message: data['sms_message']
#    ActionCable.server.broadcast "sms_message_channel", message: data
##    ActionCable.server.broadcast "sms_message_channel", html: html(data), message: data['sms_message']
#  end
  
  
  
#  def subscribed
#    room = Room.find params[:room]
#    stream_for room
#
#    # or
#    # stream_from "room_#{params[:room]}"
#  end
  
end
