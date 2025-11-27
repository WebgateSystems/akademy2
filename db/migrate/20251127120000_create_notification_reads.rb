# frozen_string_literal: true

class CreateNotificationReads < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_reads, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :notification_id, null: false
      t.datetime :read_at, null: false

      t.timestamps
    end

    add_index :notification_reads, %i[user_id notification_id], unique: true
    add_index :notification_reads, :notification_id
  end
end
