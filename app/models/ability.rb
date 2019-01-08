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
    
    if user.admin?
      
      # Customers
      ############
      can :manage, Customer
      can :create, :customers
      
      # PaymentBatches
      ############
      can :manage, PaymentBatch
      can :create, :payment_batches
      
      # Payments
      ############
      can :manage, Payment
      can :create, :payments
      
      # PaymentBatchCsvMappings
      ############
      can :manage, PaymentBatchCsvMapping do |payment_batch_csv_mapping|
        user.company == payment_batch_csv_mapping.company
      end
      can :create, PaymentBatchCsvMapping
      
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
      
    elsif user.payee?
      
      # Customers
      ############
      can :manage, Customer do |customer|
        user.customer == customer
      end
      cannot :index, Customer
      
      # SmsMessages
      ############
      can :manage, SmsMessage do |sms_message|
        user.customer == sms_message.customer
      end
      cannot :index, SmsMessage
      
      # Transactions
      ############
      can :manage, Transaction do |transaction|
        user.customer.id == transaction.custID
      end
      cannot :index, Transaction
      
      # Users
      ############
      can :manage, User do |user_record|
        user == user_record
      end
      
    elsif user.consumer?
      
      # Customers
      ############
      can :manage, Customer do |customer|
        user.customer == customer
      end
      cannot :index, Customer
      
      # SmsMessages
      ############
      can :manage, SmsMessage do |sms_message|
        user.customer == sms_message.customer
      end
      cannot :index, SmsMessage
      
      # Transactions
      ############
      can :manage, Transaction do |transaction|
        (user.customer.id == transaction.custID) or (user.customer.account.id == transaction.from_acct_id) or (user.customer.account.id == transaction.to_acct_id)
      end
      cannot :index, Transaction
      
      # Users
      ############
      can :manage, User do |user_record|
        user == user_record
      end
      
    elsif user.vendor?
      
      # Customers
      ############
      can :manage, Customer do |customer|
        user.customer == customer
      end
      cannot :index, Customer
      
      # SmsMessages
      ############
      can :manage, SmsMessage do |sms_message|
        user.customer == sms_message.customer
      end
      cannot :index, SmsMessage
      
      # Transactions
      ############
      can :manage, Transaction do |transaction|
        user.customer.id == transaction.custID
      end
      cannot :index, Transaction
      
      # Users
      ############
      can :manage, User do |user_record|
        user == user_record
      end
      
    end
    
  end
end
