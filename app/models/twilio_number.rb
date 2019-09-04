class TwilioNumber < ApplicationRecord
  belongs_to :company
  
  #############################
  #     Instance Methods      #
  #############################

  def plain_phone_number # Remove the +1 in front of the number
    phone_number.gsub(/\+1/, '')
  end
  
  def pretty_phone_number
    plain_phone_number.insert(0, '(').insert(4, ')').insert(5, ' ').insert(9, '-')
  end
  
  def send_sms(to, body, user_id)
    account_sid = ENV["TWILIO_ACCOUNT_SID"]
    auth_token = ENV["TWILIO_AUTH_TOKEN"]
    to_number = to
    from_number = phone_number
    client = Twilio::REST::Client.new account_sid, auth_token
    plain_cell_number = to.gsub(/\+1/, '')
    customer = Customer.find_by(PhoneMobile: plain_cell_number)
    
    message_body = body
    begin
      message = client.messages.create(
        :from => from_number,
        :to => to_number,
        :body => message_body,
      )
      sid = message.sid
      SmsMessage.create(sid: sid, to: to_number, from: from_number, customer_id: customer.blank? ? nil : customer.id, user_id: user_id, company_id: company_id, body: "#{message_body}")
    rescue Twilio::REST::RestError => e
      puts e.message
    end
  end
  
  
  #############################
  #     Class Methods         #
  #############################
  
  
end
