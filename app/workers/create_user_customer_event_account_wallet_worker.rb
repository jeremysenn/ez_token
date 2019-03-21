class CreateUserCustomerEventAccountWalletWorker
  include Sidekiq::Worker

  def perform(event_id, phone)
    event = Event.find(event_id)
    customer = Customer.create(CompanyNumber: 7, LangID: 1, Active: 1, GroupID: 5)
    user = User.create(phone: phone, company_id: 7, role: "basic", customer_id: customer.id, confirmed_at: Time.now)
    user.set_temporary_password
    user.save
    account = user.create_event_account(event)
    twilio_client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
    if account
      body_1 = " - your temporary password is: #{user.temporary_password}"
      body_2 = (account.can_fund_by_cc? or account.can_fund_by_ach?) ? " - you can fund your Wallet here: #{edit_account_url(account)}" : " - you can sign in here: #{new_user_session_url}"
      message_body = body_1 + body_2
      message_media = qr_code_customer_path(user.customer.barcode_access_string)
    else
      message_body = "There was a problem creating a Wallet for #{event.title}."
    end
    twilio_client.messages.create(
      :from => ENV["FROM_PHONE_NUMBER"],
      :to => user.twilio_formated_phone_number,
      :body => message_body,
      :media_url => message_media.blank? ? nil : message_media
    )
  end
end
