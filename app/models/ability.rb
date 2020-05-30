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
    
    if user.administrator? or user.super?
      
      # Customers
      ############
      can :manage, Customer do |customer|
#        user.company == customer.company
        customer.accounts.blank? or customer.accounts.exists?(CompanyNumber: user.company.id) or user.super?
      end
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
      unless user.company.twilio_number.blank?
        can :manage, SmsMessage do |sms_message|
          user.company == sms_message.company or user == sms_message.user or user.super?
        end
      end
      can :create, SmsMessage
      
      # Transactions
      ############
      can :manage, Transaction do |transaction|
         user.company == transaction.company or user.super?
      end
      
      # Users
      ############
      can :manage, User do |user_record|
        user.company == user_record.company or (user.company.accounts & user_record.accounts).any? or user.super?
      end
      can :create, User
      
      # Devices
      ############
      can :manage, Device do |device|
        user.company == device.company or user.super?
      end
      
      # Cards
      ############
      can :manage, Card do |card|
        user.company == card.device.company or user.super?
      end
      
      # Events
      ############
      can :manage, Event do |event|
        event.company == user.company or user.super?
      end
      can :create, Event
      
      # Accounts
      ############
      can :manage, Account do |account|
        account.company == user.company or user.super?
      end
      can :create, Account
      
      # Groups
      ############
      can :manage, Group
#      can :create, :groups

      # AccountTypes
      ############
      can :manage, AccountType do |account_type|
        account_type.company == user.company or user.super?
      end
      can :create, AccountType
      
      # Companies
      ############
      can :manage, Company do |company|
        company == user.company or user.super?
      end
      cannot :index, Company unless user.super?
      if user.super?
        can :create, Company
      end
      
      # ACH Logs
      ############
      can :manage, AchLog do |ach_log|
        ach_log.company == user.company
      end
      
    elsif user.collaborator?
      
      # Customers
      ############
      if user.edit_accounts?
        can :manage, Customer do |customer|
          customer.accounts.exists?(CompanyNumber: user.company.id)
        end
        can :create, Customer
      end
      if user.view_accounts?
        can :index, Customer
      end
      
      # Transactions
      ############
      if user.view_atms?
        can :manage, Transaction do |transaction|
           user.company == transaction.company
        end
      end
      
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
      unless user.company.twilio_number.blank?
        can :manage, SmsMessage
        can :create, SmsMessage
      end
      
      if user.view_atms?
        # Transactions
        ############
        can :manage, Transaction do |transaction|
           user.company == transaction.company
        end
      end
      
      if user.edit_accounts?
        # ACH Logs
        ############
        can :manage, AchLog do |ach_log|
          ach_log.company == user.company
        end
      end
      
      # Users
      ############
      
      can :manage, User do |user_record|
        if user.edit_users?
          (user.company == user_record.company) or (user_record.accounts.exists?(CompanyNumber: user.company.id))
        else
          user == user_record
        end
      end
      if user.edit_users?
        can :create, User
      end
      if user.view_users?
        can :index, User
      end
      
      # Devices
      ############
      if user.view_atms?
        can :manage, Device do |device|
          user.company == device.company 
        end
      end
      
      # Cards
      ############
      can :manage, Card do |card|
        user.company == card.device.company
      end
      
      # Events
      ############
      if user.edit_events?
        can :manage, Event do |event|
          event.company == user.company
        end
        can :create, Event
      end
      if user.view_events?
        can :index, Event
      end
      
      # Accounts
      ############
      if user.edit_accounts?
        can :manage, Account do |account|
          account.company == user.company
        end
        can :create, Account
      end
      if user.view_accounts?
        can :index, Account
      end
      
      # Groups
      ############
      can :manage, Group
#      can :create, :groups

      # AccountTypes
      ############
      if user.edit_wallet_types?
        can :manage, AccountType do |account_type|
          account_type.company == user.company
        end
        can :create, AccountType
      end
      if user.view_wallet_types?
        can :index, AccountType
      end
      
      # Companies
      ############
      can :manage, Company do |company|
        company == user.company
      end
      cannot :index, Company
      
    elsif user.basic?
      
      # SmsMessages
      ############
      unless user.company.twilio_number.blank?
        can :manage, SmsMessage do |sms_message|
          unless user.customer.blank?
            user.customer == sms_message
          else
            user == sms_message.user
          end
        end
      end
      can :create, :sms_messages
      
      # Transactions
      ############
      can :manage, Transaction do |transaction|
        user.accounts.include?(transaction.from_account) or user.accounts.include?(transaction.to_account)
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
        account.customers.include? user.customer
      end
      
      # Customers
      ############
      can :manage, Customer do |customer|
        user.customer == customer
      end
      
    end
    
  end
end
