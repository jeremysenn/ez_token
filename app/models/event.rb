class Event < ActiveRecord::Base
  establish_connection :ez_cash
  
  belongs_to :company
  has_many :accounts
  
  before_validation :downcase_join_code, :strip_join_code
  
  validates :title, presence: true
  validates :join_code, uniqueness: true, presence: true
  validates :join_code, exclusion: { in: %w( stop start help),
    message: "%{value} is reserved." }
  validates :join_response, presence: true
  
  #############################
  #     Instance Methods      #
  #############################
  
  
  
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