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
            customer = Customer.create(CompanyNumber: 7, LangID: 1, Active: 1, GroupID: 5)
            user = User.create(phone: plain_cell_number, company_id: 7, role: "basic", customer_id: customer.id, confirmed_at: Time.now)
            user.set_temporary_password
            if user.create_event_account(event)
              message.body(event.join_response)
            end
          end
        else
          if event.blank?
            message.body("Welcome back to ezToken #{user.full_name}. Sorry, we're not able to find an open event with that join code.")
          else
            if user.create_event_account(event)
              message.body(event.join_response)
              message.media(qr_code_customer_path(user.customer.barcode_access_string))
            end
          end
        end
    end
    render_twiml response

  end
  
end