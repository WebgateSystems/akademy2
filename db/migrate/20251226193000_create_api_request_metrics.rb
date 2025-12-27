# frozen_string_literal: true

class CreateApiRequestMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :api_request_metrics, id: :uuid do |t|
      t.datetime :bucket_start, null: false
      t.integer :requests_count, null: false, default: 0
      t.integer :unique_users_count, null: false, default: 0
      t.integer :unique_ips_count, null: false, default: 0
      t.float :avg_response_time_ms

      t.timestamps
    end

    add_index :api_request_metrics, :bucket_start, unique: true
  end
end
