class FileUploadWorker
  include Sidekiq::Worker

  def perform(transaction_id, image_path)
    transaction = Transaction.find(transaction_id)
    transaction.upload_file = File.open(image_path)
    transaction.save!(validate: false)
  end
    
end
