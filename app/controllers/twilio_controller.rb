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
    body = params[:Body].truncate(255) # Do not allow to be larger than 255 so doesn't cause a DB error
    keyword = body.downcase.strip
    event = Event.now_open.find_by(join_code: keyword)
    message_sid = params[:MessageSid]
    SmsMessage.create(sid: message_sid, to: to, from: from, company_id: event.blank? ? nil : event.company_id, body: "#{body}")
    
    response = Twilio::TwiML::MessagingResponse.new
    response.message do |message|
        if user.blank?
          if event.blank?
            message.body("Welcome to EZ Token #{plain_cell_number}! Sorry, we're not able to find an open event with that join code.")
          else
            message.body(event.join_response)
            CreateUserCustomerEventAccountWalletWorker.perform_async(event.id, plain_cell_number)
            ### Put all of this into background process
#            customer = Customer.create(CompanyNumber: 7, LangID: 1, Active: 1, GroupID: 5)
#            user = User.create(phone: plain_cell_number, company_id: 7, role: "basic", customer_id: customer.id, confirmed_at: Time.now)
#            user.set_temporary_password
#            user.save
#            account = user.create_event_account(event)
#            if account
#              body_1 = event.join_response
#              body_2 = " - your temporary password is: #{user.temporary_password}"
#              body_3 = (account.can_fund_by_cc? or account.can_fund_by_ach?) ? " - you can fund your Wallet here: #{edit_account_url(account)}" : " - you can sign in here: #{new_user_session_url}"
#              message.body(body_1 + body_2 + body_3)
#              message.media(qr_code_customer_path(user.customer.barcode_access_string))
#            else
#              message.body("There was a problem creating a Wallet for #{event.title}.")
#            end
            ### End Put all of this into background process
          
          end
        else
          if event.blank?
            message.body("Welcome back to ezToken #{user.full_name}! Sorry, we're not able to find an open event with that join code.")
          else
#            message.body("Welcome back to ezToken!")
            CreateEventAccountWalletWorker.perform_async(event.id, user.id)
            ### Put all of this into background process
#            account = user.create_event_account(event)
#            if account
#              body_1 = event.join_response
#              body_2 = (account.can_fund_by_cc? or account.can_fund_by_ach?) ? " - you can fund your Wallet here: #{edit_account_url(account)}" : ''
#              message.body(body_1 + body_2)
#              message.media(qr_code_customer_path(user.customer.barcode_access_string))
#            else
#              message.body("You already have a Wallet for #{event.title}.")
#            end
          end
        end
    end
    render_twiml response

  end
  
end