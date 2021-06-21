class Fee < ActiveRecord::Base
  
  establish_connection :ez_cash
  
  belongs_to :device, optional: true
  belongs_to :company, optional: true
  
  scope :quick_pay, -> { where(transfer_type: "Quick Pay", active: true) }
  scope :transfer, -> { where(transfer_type: "Transfer", active: true) }
  scope :withdrawal, -> { where(transfer_type: "Withdrawal", active: true) }
  
  #############################
  #     Instance Methods      #
  #############################
  
  def quick_pay?
    transfer_type == 'Quick Pay'
  end
  
  def transfer?
    transfer_type == 'Transfer'
  end
  
  def withdrawal?
    transfer_type == 'Withdrawal'
  end
  
  def percentage?
    fee_type == 'Percentage'
  end
  
  def fixed?
    fee_type == 'Fixed'
  end
  
  #############################
  #     Class Methods         #
  #############################
end