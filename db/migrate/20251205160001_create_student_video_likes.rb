# frozen_string_literal: true

class CreateStudentVideoLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :student_video_likes, id: :uuid do |t|
      t.references :student_video, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    # Each user can like a video only once
    add_index :student_video_likes, %i[student_video_id user_id], unique: true
  end
end
