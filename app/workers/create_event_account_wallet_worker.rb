class CreateEventAccountWalletWorker
  include Sidekiq::Worker

  def perform(event_id)
    event = Event.find(event_id)
    account = user.create_event_account(event)
    if account
      message_body = (account.can_fund_by_cc? or account.can_fund_by_ach?) ? " - you can fund your Wallet here: #{edit_account_url(account)}" : ''
      message_media = qr_code_customer_path(user.customer.barcode_access_string)
    else
      message_body = "You already have a Wallet for #{event.title}."
    end
    twilio_client.messages.create(
      :from => ENV["FROM_PHONE_NUMBER"],
      :to => user.twilio_formated_phone_number,
      :body => message_body,
      :media_url => message_media.blank? ? nil : message_media
    )
  end
end
