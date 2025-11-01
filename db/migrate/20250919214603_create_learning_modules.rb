class CreateLearningModules < ActiveRecord::Migration[8.0]
  def change
    create_table :learning_modules, id: :uuid do |t|
      t.references :unit, null: false, type: :uuid, foreign_key: true
      t.string  :title, null: false
      t.integer :order_index, null: false, default: 0
      t.boolean :single_flow, null: false, default: false
      t.timestamps
    end
  end
end
