class CreateTeacherClassAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_class_assignments, id: :uuid do |t|
      t.uuid :teacher_id, null: false
      t.references :school_class, null: false, type: :uuid, foreign_key: true
      t.string :role, null: false # main/assistant
      t.timestamps
    end
    add_index :teacher_class_assignments, %i[teacher_id school_class_id], unique: true,
                                                                          name: :index_teacher_assignments_unique
    add_foreign_key :teacher_class_assignments, :users, column: :teacher_id
  end
end
