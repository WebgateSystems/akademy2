class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :key,  null: false
      t.string :name, null: false
      t.timestamps
    end
    add_index :roles, :key, unique: true
  end
end
