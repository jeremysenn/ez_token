class Signature < ActiveRecord::Base
  
  self.table_name= 'fine_print_signatures'
  
  belongs_to :user
  belongs_to :contract
  
  #############################
  #     Instance Methods      #
  #############################
  
  
  
  #############################
  #     Class Methods         #
  #############################
  
  
end