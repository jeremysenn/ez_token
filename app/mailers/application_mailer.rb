class ApplicationMailer < ActionMailer::Base
  default from: 'info@tranact.com'
  layout 'mailer'
  
  def send_admins_transaction_dispute_email_notification(user, to_emails, transaction, details)
    @from_email = user.email
    @to = to_emails
    @transaction = transaction
    @details = details
    @user = user
    @subject = "Transaction #{transaction.id} disputed"
    mail(to: @to, from: @from_email, reply_to: @from_email, subject: @subject)
  end
end
