class CreateEventAccountWalletWorker
  include Sidekiq::Worker

  def perform(event_id, user_id)
    event = Event.find(event_id)
    user = User.find(user_id)
    account = user.create_event_account(event)
    if account
#      message_body = (account.can_fund_by_cc? or account.can_fund_by_ach?) ? " - you can fund your Wallet here: #{edit_account_url(account)}" : ''
      message_body = (account.can_fund_by_cc? or account.can_fund_by_ach?) ? " - you can fund your Wallet here: https://#{ENV['APPLICATION_HOST']}/accounts/#{account.id}/edit" : ''
#      message_media = qr_code_customer_path(user.customer.barcode_access_string)
      message_media = "https://#{ENV['APPLICATION_HOST']}/customers/#{user.customer.barcode_access_string}/qr_code"
    else
      message_body = "You already have a Wallet for #{event.title}."
    end
    twilio_client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
    twilio_client.messages.create(
      :from => ENV["FROM_PHONE_NUMBER"],
      :to => user.twilio_formated_phone_number,
      :body => message_body,
      :media_url => message_media.blank? ? nil : message_media
    )
  end
end
