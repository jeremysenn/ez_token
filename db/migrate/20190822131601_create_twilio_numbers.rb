class CreateTwilioNumbers < ActiveRecord::Migration[5.1]
  def change
    create_table :twilio_numbers do |t|
      t.string :phone_number
      t.integer :company_id
      t.string :sid

      t.timestamps
    end
  end
end
