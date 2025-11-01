class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans, id: :uuid do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.jsonb  :limits,   null: false, default: {}
      t.jsonb  :features, null: false, default: {}
      t.timestamps
    end
    add_index :plans, :key, unique: true
  end
end
