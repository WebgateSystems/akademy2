class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events, id: :uuid do |t|
      t.references :user,   type: :uuid, foreign_key: true
      t.references :school, type: :uuid, foreign_key: true
      t.string  :event_type, null: false
      t.jsonb   :data,       null: false, default: {}
      t.datetime :occurred_at, null: false
      t.string :client
      t.timestamps
    end
    add_index :events, :event_type
    add_index :events, :occurred_at
  end
end
