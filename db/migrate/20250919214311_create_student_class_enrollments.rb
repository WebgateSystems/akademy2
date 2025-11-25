class CreateStudentClassEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :student_class_enrollments, id: :uuid do |t|
      t.uuid :student_id, null: false
      t.references :school_class, null: false, type: :uuid, foreign_key: true
      t.string :status, null: false, default: 'pending' # pending/active
      t.datetime :joined_at
      t.timestamps
    end
    add_index :student_class_enrollments, %i[student_id school_class_id], unique: true,
                                                                          name: :index_student_enrollments_unique
    add_foreign_key :student_class_enrollments, :users, column: :student_id
  end
end
