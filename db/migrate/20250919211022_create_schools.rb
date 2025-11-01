class CreateSchools < ActiveRecord::Migration[8.0]
  def change
    create_table :schools, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :city
      t.string :country
      t.string :logo
      t.timestamps
    end
    add_index :schools, :slug, unique: true
  end
end
