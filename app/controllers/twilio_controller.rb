require 'twilio-ruby'

class TwilioController < ApplicationController
  include Webhookable
  protect_from_forgery except: :voice
#  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token

#  after_filter :set_header
  after_action :set_header

  def voice
    from = params[:From]
    plain_cell_number = from.gsub(/\+1/, '')
    user = User.find_by(phone: plain_cell_number)
    
    response = Twilio::TwiML::VoiceResponse.new
    if user.blank?
      response.say(message: "Hey there, thanks for the call. Enjoy some music.", :voice => 'alice')
    else
      response.say(message: "Hey there #{user.first_name}, thanks for the call. Enjoy some music.", :voice => 'alice')
    end
    response.play(url: 'http://linode.rabasa.com/cantina.mp3')
    
    render_twiml response
  end

  def sms
    from = params[:From]
    plain_cell_number = from.gsub(/\+1/, '')
    user = User.find_by(phone: plain_cell_number)
    to = params[:To] 
    body = params[:Body].truncate(255) # Do not allow to be larger than 255 so doesn't cause a PostgreSQL error
    keyword = body.downcase.strip
    event = Event.now_open.find_by(join_code: keyword)
    message_sid = params[:MessageSid]
    
    response = Twilio::TwiML::MessagingResponse.new
    response.message do |message|
        if user.blank?
          if event.blank?
            message.body("Welcome to EZ Token #{plain_cell_number}. Sorry, we're not able to find an open event with that join code.")
          else
#            user = User.create(phone: plain_cell_number, company_id: company.id, role: "consumer")
#            user.create_consumer_customer_and_account_records
#            user.set_temporary_password
#            message.body("Welcome to EZ Token #{plain_cell_number}. We successfully found #{event.title}.")
            message.body(event.join_response)
          end
        else
          if event.blank?
            message.body("Welcome back to ezToken #{user.full_name}. Sorry, we're not able to find an open event with that join code.")
          else
#            message.body("Welcome back to ezToken #{user.full_name}. We successfully found #{event.title}.")
            user.create_event_account(event)
            message.body(event.join_response)
            message.media(qr_code_customer_path(user.customer.barcode_access_string))
          end
        end
    end
    render_twiml response

  end
  
end