# frozen_string_literal: true

class FixNotificationsForeignKeysCascade < ActiveRecord::Migration[8.1]
  def up
    # Remove existing foreign keys for notifications that need CASCADE
    remove_foreign_key :notifications, :users if foreign_key_exists?(:notifications, :users)
    remove_foreign_key :notifications, column: :read_by_user_id if foreign_key_exists?(:notifications,
                                                                                       column: :read_by_user_id)

    # Add foreign keys with ON DELETE CASCADE
    # Notifications: CASCADE when user is deleted
    add_foreign_key :notifications, :users, on_delete: :cascade

    # Notifications: CASCADE when read_by_user is deleted
    add_foreign_key :notifications, :users, column: :read_by_user_id, on_delete: :cascade
  end

  def down
    # Remove CASCADE foreign keys
    remove_foreign_key :notifications, :users if foreign_key_exists?(:notifications, :users)
    remove_foreign_key :notifications, column: :read_by_user_id if foreign_key_exists?(:notifications,
                                                                                       column: :read_by_user_id)

    # Restore original foreign keys without CASCADE
    add_foreign_key :notifications, :users
    add_foreign_key :notifications, :users, column: :read_by_user_id
  end
end
