# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.0]
  def up
    unless table_exists?(:notifications)
      create_table :notifications, id: :uuid do |t|
        # User who triggered the notification (optional)
        t.references :user, null: true, type: :uuid, foreign_key: true
        # School context (optional) - Rails auto-creates index
        t.references :school, null: true, type: :uuid, foreign_key: true
        # teacher_awaiting_approval, student_awaiting_approval, report_ready, etc.
        t.string :notification_type, null: false
        t.string :title, null: false
        t.text :message, null: false
        # Additional data (teacher_id, student_id, report_id, etc.)
        t.jsonb :metadata, null: false, default: {}
        t.datetime :read_at # When notification was read (null = unread)
        # Who read it (for multi-user notifications)
        t.references :read_by_user, null: true, type: :uuid, foreign_key: { to_table: :users }
        # admin, principal, school_manager, teacher, student
        t.string :target_role, null: false
        # When the underlying issue was resolved (e.g., teacher approved)
        t.datetime :resolved_at

        t.timestamps
      end
    end

    # school_id index is automatically created by Rails for t.references :school, so we don't add it manually
    add_index :notifications, :notification_type unless index_exists?(:notifications, :notification_type)
    add_index :notifications, :target_role unless index_exists?(:notifications, :target_role)
    add_index :notifications, :read_at unless index_exists?(:notifications, :read_at)
    add_index :notifications, :resolved_at unless index_exists?(:notifications, :resolved_at)
    add_index :notifications, %i[target_role school_id read_at] unless index_exists?(:notifications,
                                                                                     %i[target_role school_id read_at])
  end

  def down
    drop_table :notifications if table_exists?(:notifications)
  end
end
