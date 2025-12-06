# frozen_string_literal: true

class CreateContentLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :content_likes, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :content, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :content_likes, %i[user_id content_id], unique: true

    # Add likes_count to contents for counter cache
    add_column :contents, :likes_count, :integer, default: 0, null: false
  end
end
