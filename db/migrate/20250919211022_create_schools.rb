class CreateSchools < ActiveRecord::Migration[8.0]
  def change
    create_table :schools, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :address
      t.string :city, default: 'Gdynia', null: false
      t.string :country, default: 'PL', null: false
      t.string :postcode
      t.string :homepage
      t.string :phone
      t.string :email
      t.string :logo
      t.timestamps
    end
    add_index :schools, :slug, unique: true
  end
end
