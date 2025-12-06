# frozen_string_literal: true

class CreateStudentVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :student_videos, id: :uuid do |t|
      # Author (student who uploaded)
      t.references :user, null: false, foreign_key: true, type: :uuid
      # Subject/topic for the video
      t.references :subject, null: false, foreign_key: true, type: :uuid
      # School of the student (for filtering, but NOT required scope)
      t.references :school, null: true, foreign_key: true, type: :uuid

      # Video metadata
      t.string :title, null: false
      t.text :description
      t.string :file, null: false # CarrierWave file path
      t.string :thumbnail # Optional thumbnail
      t.integer :duration_sec
      t.bigint :file_size_bytes

      # Moderation
      t.string :status, null: false, default: 'pending' # pending, approved, rejected
      t.references :moderated_by, null: true, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :moderated_at
      t.text :rejection_reason

      # YouTube integration (after approval)
      t.string :youtube_url
      t.string :youtube_id
      t.datetime :youtube_uploaded_at

      # Likes count (denormalized for performance)
      t.integer :likes_count, null: false, default: 0

      t.timestamps
    end

    add_index :student_videos, :status
    add_index :student_videos, :created_at
    add_index :student_videos, %i[subject_id status]
    add_index :student_videos, %i[school_id status]
    add_index :student_videos, %i[user_id status]
  end
end
