class CustomerCard < ActiveRecord::Base
  
  establish_connection :ez_cash
  self.primary_key = 'CardID'
  self.table_name= 'CustomerCards'
  
#  belongs_to :company, :foreign_key => "CompanyNumber", optional: true
  belongs_to :customer, :foreign_key => "CustomerID", optional: true
  belongs_to :account, :foreign_key => "ActID", optional: true
  
  #############################
  #     Instance Methods      #
  #############################
  
  
  #############################
  #     Class Methods         #
  #############################
  
  
end