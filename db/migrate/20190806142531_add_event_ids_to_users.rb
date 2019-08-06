class AddEventIdsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :admin_event_ids, :text
  end
end
