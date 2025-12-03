class CreateTeacherSchoolEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_school_enrollments, id: :uuid do |t|
      t.uuid :teacher_id, null: false
      t.references :school, null: false, type: :uuid, foreign_key: true
      t.string :status, null: false, default: 'pending' # pending/approved
      t.datetime :joined_at
      t.timestamps
    end
    add_index :teacher_school_enrollments, %i[teacher_id school_id], unique: true,
                                                                     name: :index_teacher_enrollments_unique
    add_foreign_key :teacher_school_enrollments, :users, column: :teacher_id
  end
end
