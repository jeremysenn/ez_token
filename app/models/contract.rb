class Contract < ActiveRecord::Base
  
  self.table_name= 'fine_print_contracts'
  
  belongs_to :company
  has_many :account_types
  has_many :signatures
  
  #############################
  #     Instance Methods      #
  #############################
  
  def is_published?
    !version.nil?
  end
  
  #############################
  #     Class Methods         #
  #############################
  
  
end