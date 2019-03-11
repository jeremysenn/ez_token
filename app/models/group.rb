class Group < ActiveRecord::Base
  self.primary_key = 'GroupID'
  self.table_name= 'Groups'
  
  establish_connection :ez_cash
  
  has_many :customers, :foreign_key => "GroupID"
  
  #############################
  #     Instance Methods      #
  #############################
  
  def caddy?
    self.GroupID == 13
  end
  
  def member?
    self.GroupID == 14
  end
  
  def anonymous?
    self.GroupID == 15
  end
  
  def consumer?
    self.GroupID == 16
  end
  
  def vendor?
    self.GroupID == 17
  end
  
  def payee?
    self.GroupID == 18
  end
  
  def type
    if caddy?
      "Caddy"
    elsif member?
      "Member"
    elsif consumer?
      "Consumer"
    elsif vendor?
      "Vendor"
    elsif payee?
      "Payee"
    elsif anonymous?
      "Anonymous"
    else
      "Unknown"
    end
  end
  
  def description
    self.GroupDescription
  end
  
  def active?
    self.Active == 1
  end
  
  
  #############################
  #     Class Methods      #
  #############################
  
  def self.all_selections
    [["Anonymous", 15], ["Caddy", 13], ["Consumer", 16], ["Member", 14], ["Payee", 18], ["Vendor", 17]]
  end
  
  def self.admin_selections
    [["Anonymous", 15], ["Payee", 18]]
  end
  
  def self.caddy_admin_selections
    [["Caddy", 13], ["Member", 14]]
  end
  
  def self.event_admin_selections
    [["Consumer", 16], ["Vendor", 17]]
  end
  
  def self.selections_by_user_role(user)
    if user.admin?
      self.admin_selections
    elsif user.caddy_admin?
      self.caddy_admin_selections
    elsif user.event_admin?
      self.event_admin_selections
    else
      self.all_selections
    end
  end
  
end
