class Event < ActiveRecord::Base
  establish_connection :ez_cash
  
  belongs_to :company
#  has_many :accounts
  has_and_belongs_to_many :accounts, :join_table => :accounts_events, :uniq => true
  has_many :customers, through: :accounts
  has_many :transactions
  
  before_validation :downcase_join_code, :strip_join_code, unless: Proc.new { |event| event.join_code.blank? }
  
  scope :now_open, -> { where("start_date <= ? AND end_date >= ?", Date.today, Date.today) }
  scope :accounts_do_not_expire, -> { where(expire_accounts: [nil, 0]) }
  scope :accounts_expire, -> { where(expire_accounts: 1) }
  
  validates :title, presence: true
#  validates :join_code, uniqueness: true, presence: true
  validates :join_code, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :join_code, exclusion: { in: %w( stop start help),
    message: "%{value} is reserved." }
#  validates :join_response, presence: true
  validate :no_duplicate_customers
  validate :account_type_required_if_join_code

  accepts_nested_attributes_for :accounts #, allow_destroy: true
  
  #############################
  #     Instance Methods      #
  #############################
  
  def started?
    (start_date.to_date <= Date.today)
  end
  
  def open?
#    (start_time.in_time_zone(time_zone) < Time.now.in_time_zone(time_zone)) and (Time.now.in_time_zone(time_zone) < end_time.in_time_zone(time_zone))
    (start_date.to_date <= Date.today) and (Date.today <= end_date.to_date)
  end
  
  def closed?
    unless end_date.blank?
#      end_time.in_time_zone(time_zone) < Time.now.in_time_zone(time_zone)
      end_date.to_date < Date.today
    else
      false
    end
  end
  
  def member_accounts
#    accounts.select {|a| a.member?}
    accounts.joins(:customer).where("customer.GroupID = ?", 14)
  end
  
  def includes_customer?(customer)
    customers = accounts.joins(:customer).where("customer.CustomerID = ?", customer.id)
    return (not customers.blank?)
  end
  
  def no_duplicate_customers
    unless accounts.map{|a| a.CustomerID} == accounts.map{|a| a.CustomerID}.uniq
      errors.add(:error, 'Duplicate customer')
    end
  end
  
  def account_type_required_if_join_code
    if join_code.present? and account_type_id.blank?
      errors.add(:error, 'You must choose a Wallet Type if you have a Join Code')
    end
  end
  
  def join_by_sms_wallet_type
    unless account_type_id.blank?
      AccountType.find(account_type_id)
    else
      nil
    end
  end
  
  #############################
  #     Class Methods         #
  #############################
  
  
  private
    def downcase_join_code
      self.join_code.downcase!
    end
    
    def strip_join_code
      self.join_code.strip!
    end
  
end