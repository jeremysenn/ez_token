class AddFromAndSidToSmsMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :sms_messages, :from, :string
    add_column :sms_messages, :sid, :string
  end
end
