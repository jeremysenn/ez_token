class AccountType < ActiveRecord::Base
  establish_connection :ez_cash
  self.primary_key = 'AccountTypeID'
  self.table_name= 'AccountTypes'
  
  has_many :accounts, :foreign_key => "ActTypeID"
  belongs_to :company, :foreign_key => "CompanyNumber"
  belongs_to :contract
  
  #############################
  #     Instance Methods      #
  #############################
  
  def description
    self.AccountTypeDesc
  end
  
  def funding_bank_account?
    self.AccounTypeDesc == "Funding Bank Account"
  end
  
  def heavy_metal_debit?
    self.AccounTypeDesc == "Heavy Metal Debit"
  end
  
  def company_account?
    self.AccounTypeDesc == "Company Account"
  end
  
  def company_fee_account?
    self.AccounTypeDesc == "Company Fee Account"
  end
  
  def can_fund_by_ach?
    self.CanFundByACH == 1
  end
  
  def can_fund_by_cc?
    self.CanFundByCC == 1
  end
  
  def can_fund_by_cash?
    self.CanFundByCash == 1
  end
  
  def can_withdraw?
    self.CanWithdraw == 1
  end
  
  def withdrawal_all?
    self.WithdrawAll == 1
  end
  
  def can_pull?
    self.CanPull == 1
  end
  
  def can_request_payment_by_search?
    self.CanRequestPmtBySearch == 1
  end
  
  def can_request_payment_by_scan?
    self.CanRequestPmtByScan == 1
  end
  
  def can_send_payment?
    self.CanSendPmt == 1
  end
  
  def can_be_pulled_by_search?
    self.CanBePulledBySearch == 1
  end
  
  def can_be_pulled_by_scan?
    self.CanBePulledByScan == 1
  end
  
  def can_be_pushed_by_scan?
    self.CanBePushedByScan == 1
  end
  
  def heavy_metal_debit?
    self.AccountTypeID == 6
  end
  
  def company_account?
    self.AccountTypeID == 7
  end
  
  def default_minimum_balance
    unless self.DefaultMinBal.blank?
      self.DefaultMinBal
    else
      0
    end
  end
  
  def accounts_cash_total
    sum = 0
    accounts.each do |account|
      sum = sum + account.balance unless account.balance.blank? or account == account.company.transaction_account
    end
    return sum
  end
  
  #############################
  #     Class Methods      #
  #############################
  
end