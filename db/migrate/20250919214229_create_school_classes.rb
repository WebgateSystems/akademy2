class CreateSchoolClasses < ActiveRecord::Migration[8.0]
  def change
    create_table :school_classes, id: :uuid do |t|
      t.references :school, null: false, type: :uuid, foreign_key: true
      t.string  :name, null: false        # np. "4B"
      t.string  :year, null: false        # np. "2025/2026"
      t.uuid    :qr_token, null: false
      t.jsonb   :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :school_classes, :qr_token, unique: true
    add_index :school_classes, %i[school_id name year], unique: true, name: :index_classes_on_school_name_year
  end
end
