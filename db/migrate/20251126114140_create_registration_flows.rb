class CreateRegistrationFlows < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_flows, id: :uuid do |t|
      t.string  :step, null: false, default: 'profile'
      t.string  :phone_code
      t.boolean :phone_verified, default: false
      t.string  :pin_temp
      t.datetime :expires_at, null: false
      t.jsonb :data, default: {}

      t.timestamps
    end

    add_index :registration_flows, :expires_at
  end
end
