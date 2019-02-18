class Group < ActiveRecord::Base
  self.primary_key = 'GroupID'
  self.table_name= 'Groups'
  
  establish_connection :ez_cash
  
  has_many :customers
  
  #############################
  #     Instance Methods      #
  #############################
  
  
  #############################
  #     Class Methods      #
  #############################
  
end
