class SystemSetting < ActiveRecord::Base
  establish_connection :ez_cash
  self.primary_key = 'setting'
  self.table_name= 'SystemSettings'
  
end