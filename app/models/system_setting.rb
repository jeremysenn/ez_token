class SystemSetting < ActiveRecord::Base
  establish_connection :ez_cash
  self.primary_key = 'setting'
  self.table_name= 'SystemSettings'
  
  #############################
  #     Class Methods         #
  #############################
  
  def self.qrcode_html_source
    self.find_by(Setting: "QRCode HTML Source")
  end
  
  def self.qrcode_html_source_value
    qrcode_html_source.Value
  end
  
end