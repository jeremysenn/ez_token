class AddPermissionAttributesToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :view_events, :boolean
    add_column :users, :edit_events, :boolean
    
    add_column :users, :view_wallet_types, :boolean
    add_column :users, :edit_wallet_types, :boolean
    
    add_column :users, :view_accounts, :boolean
    add_column :users, :edit_accounts, :boolean
    
    add_column :users, :view_users, :boolean
    add_column :users, :edit_users, :boolean
    
    add_column :users, :view_atms, :boolean
    
    add_column :users, :can_quick_pay, :boolean
  end
end
