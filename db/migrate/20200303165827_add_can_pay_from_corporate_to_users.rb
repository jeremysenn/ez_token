class AddCanPayFromCorporateToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :can_pay_from_corporate, :boolean
  end
end
