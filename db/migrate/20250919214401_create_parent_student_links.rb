class CreateParentStudentLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :parent_student_links, id: :uuid do |t|
      t.uuid :parent_id,  null: false
      t.uuid :student_id, null: false
      t.string :relation, null: false # mother/father/guardian/other
      t.timestamps
    end
    add_index :parent_student_links, [ :parent_id, :student_id ], unique: true, name: :index_parent_student_unique
    add_foreign_key :parent_student_links, :users, column: :parent_id
    add_foreign_key :parent_student_links, :users, column: :student_id
  end
end
