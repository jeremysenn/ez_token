class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
       user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
    
    if user.administrator?
      
      # Customers
      ############
      can :manage, Customer
      can :create, Customer
      
      # PaymentBatches
      ############
      can :manage, PaymentBatch
      can :create, PaymentBatch
      
      # Payments
      ############
      can :manage, Payment
      can :create, Payment
      
      # PaymentBatchCsvMappings
      ############
      can :manage, PaymentBatchCsvMapping do |payment_batch_csv_mapping|
        user.company == payment_batch_csv_mapping.company
      end
      can :create, PaymentBatchCsvMapping
      
      # SmsMessages
      ############
      can :manage, SmsMessage
      can :create, SmsMessage
      
      # Transactions
      ############
      can :manage, Transaction do |transaction|
         user.company == transaction.company
      end
      
      # Users
      ############
      can :manage, User do |user_record|
        user.company == user_record.company 
      end
      can :create, User
      
      # Devices
      ############
      can :manage, Device do |device|
        user.company == device.company 
      end
      
      # Cards
      ############
      can :manage, Card do |card|
        user.company == card.device.company
      end
      
      # Events
      ############
      can :manage, Event do |event|
        event.company == user.company
      end
      can :create, Event
      
      # Accounts
      ############
      can :manage, Account do |account|
        account.company == user.company
      end
      can :create, Account
      
      # Groups
      ############
      can :manage, Group
#      can :create, :groups

      # AccountTypes
      ############
      can :manage, AccountType do |account_type|
        account_type.company == user.company
      end
      can :create, AccountType
      
    elsif user.basic?
      
      # SmsMessages
      ############
      can :manage, SmsMessage
      can :create, :sms_messages
      
      # Transactions
      ############
      can :manage, Transaction do |transaction|
         user.company == transaction.company
      end
      
      # Users
      ############
      can :manage, User do |user_record|
        user == user_record 
      end
      
      # Devices
      ############
      can :manage, Device do |device|
        user.company == device.company and user.devices.include? device
      end
      
      # Cards
      ############
      can :manage, Card do |card|
         user.company == card.device.company and user.devices.include? card.device
      end
      
      # Accounts
      ############
      can :manage, Account do |account|
        account.customer == user.customer
      end
      
    end
    
  end
end
