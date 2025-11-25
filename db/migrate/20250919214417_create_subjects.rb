class CreateSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :subjects, id: :uuid do |t|
      t.references :school, type: :uuid, foreign_key: true # null => global subject
      t.string  :title, null: false
      t.string  :slug,  null: false
      t.integer :order_index, null: false, default: 0
      t.timestamps
    end
    add_index :subjects, %i[school_id slug], unique: true, name: :index_subjects_on_school_and_slug
  end
end
