class CustomerCard < ActiveRecord::Base
  
  establish_connection :ez_cash
  self.primary_key = 'CardID'
  self.table_name= 'CustomerCards'
  
  belongs_to :company, :foreign_key => "CompanyNumber"
  belongs_to :customer, :foreign_key => "CustomerID"
  belongs_to :account, :foreign_key => "ActID"
  
  #############################
  #     Instance Methods      #
  #############################
  
  
  #############################
  #     Class Methods         #
  #############################
  
  
end