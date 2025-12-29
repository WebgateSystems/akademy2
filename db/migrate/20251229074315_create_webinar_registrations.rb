# frozen_string_literal: true

class CreateWebinarRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :webinar_registrations, id: :uuid do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :position # Stanowisko (optional)
      t.string :school_name # Szkoła (optional)
      t.string :phone # Telefon (optional)
      t.string :webinar_id, null: false # identyfikator webinaru
      t.datetime :confirmation_sent_at
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :webinar_registrations, :email
    add_index :webinar_registrations, :webinar_id
    add_index :webinar_registrations, %i[email webinar_id], unique: true
  end
end
