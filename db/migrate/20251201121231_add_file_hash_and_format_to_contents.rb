# frozen_string_literal: true

class AddFileHashAndFormatToContents < ActiveRecord::Migration[8.1]
  def change
    change_table :contents, bulk: true do |t|
      t.string :file_hash
      t.string :file_format
    end

    add_index :contents, :file_hash
  end
end
