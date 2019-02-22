class Event < ActiveRecord::Base
  establish_connection :ez_cash
  
  belongs_to :company
#  has_many :accounts
  has_and_belongs_to_many :accounts, :join_table => :accounts_events
  
  before_validation :downcase_join_code, :strip_join_code
  
  scope :now_open, -> { where("start_date <= ? AND end_date >= ?", Date.today, Date.today) }
  
  validates :title, presence: true
  validates :join_code, uniqueness: true, presence: true
  validates :join_code, exclusion: { in: %w( stop start help),
    message: "%{value} is reserved." }
  validates :join_response, presence: true
  
  #############################
  #     Instance Methods      #
  #############################
  
  def started?
    (start_date <= Date.today)
  end
  
  def open?
#    (start_time.in_time_zone(time_zone) < Time.now.in_time_zone(time_zone)) and (Time.now.in_time_zone(time_zone) < end_time.in_time_zone(time_zone))
    (start_date <= Date.today) and (Date.today <= end_time)
  end
  
  def closed?
    unless end_time.blank?
#      end_time.in_time_zone(time_zone) < Time.now.in_time_zone(time_zone)
      end_date < Date.today
    else
      false
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