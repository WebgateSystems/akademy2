class CreateUnits < ActiveRecord::Migration[8.0]
  def change
    create_table :units, id: :uuid do |t|
      t.references :subject, null: false, type: :uuid, foreign_key: true
      t.string  :title, null: false
      t.integer :order_index, null: false, default: 0
      t.timestamps
    end
  end
end
