class CustomerBarcode < ActiveRecord::Base
  establish_connection :ez_cash
  self.primary_key = 'RowID'
  self.table_name= 'CustomerBarcode'
  
  belongs_to :customer, :foreign_key => 'CustomerID'
  belongs_to :company, :foreign_key => 'CompanyNumber'
  
  #############################
  #     Instance Methods      #
  #############################
  
  def used?
    self.Used == 1
  end
  
  def not_used?
    self.Used == 0
  end
  
  #############################
  #     Class Methods      #
  #############################
  
  
end