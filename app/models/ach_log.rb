class AchLog < ActiveRecord::Base
  establish_connection :ez_cash
  self.primary_key = 'ID'
  self.table_name= 'ACHLog'
  
  belongs_to :event
  belongs_to :company
  
  #############################
  #     Instance Methods      #
  #############################
  
  def company
    event.company
  end
  
  def decoded_csv_report
    decoded_report = Base64.decode64(self.Report).unpack("H*").first
    unless decoded_report.blank?
      return Decrypt.decryption(decoded_report)
    else
      nil
    end
  end
  
  #############################
  #     Class Methods      #
  #############################
  
  
end