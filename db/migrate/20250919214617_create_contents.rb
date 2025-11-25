class CreateContents < ActiveRecord::Migration[8.0]
  def change
    create_table :contents, id: :uuid do |t|
      t.references :learning_module, null: false, type: :uuid, foreign_key: true
      t.string  :content_type, null: false # video/infographic/quiz/pdf/webinar/asset
      t.string  :title,        null: false
      t.integer :order_index,  null: false, default: 0
      t.jsonb   :payload,      null: false, default: {}
      t.integer :duration_sec
      # CarrierWave ścieżki/identyfikatory
      t.string  :file
      t.string  :poster
      t.string  :subtitles
      t.timestamps
    end
    add_index :contents, %i[learning_module_id order_index], name: :index_contents_on_module_and_order
    add_index :contents, :content_type
  end
end
