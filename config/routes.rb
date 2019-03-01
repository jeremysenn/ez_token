Rails.application.routes.draw do
#  devise_for :users
  devise_for :users, controllers: { confirmations: 'confirmations' }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  get 'welcome/index'
  root 'welcome#index'
  
  resources :customers do
    member do
      get 'one_time_payment'
      get 'barcode'
      get 'send_barcode_link_sms_message'
      get 'send_barcode_sms_message'
      get 'find_by_barcode'
      get 'qr_code'
      get 'create_account_and_add_to_event'
    end
    collection do
      post 'send_sms_message'
    end
  end
  
#  resources :users
  resources :users_admin, :controller => 'users'
  
  resources :transactions do
    member do
      get 'reverse'
    end
    collection do
      post 'quick_pay'
      post 'quick_purchase'
      post 'send_payment'
      post 'send_payment_from_qr_code_scan'
    end
  end
  resources :sms_messages
  resources :payment_batches do
    collection do
      get 'csv_template'
    end
  end
  
  resources :payments
  resources :devices do 
    member do
      get 'send_atm_command'
    end
  end
  resources :payment_batch_csv_mappings
  resources :cards
  
  post 'twilio/sms' => 'twilio#sms'
  post 'twilio/voice' => 'twilio#voice'
  
  resources :events
  
  resources :accounts
  
end
