# frozen_string_literal: true

class FixTeacherClassAssignmentsUniqueIndex < ActiveRecord::Migration[8.0]
  def up
    # Remove old unique index that doesn't include role
    remove_index :teacher_class_assignments, name: :index_teacher_assignments_unique, if_exists: true

    # Add new unique index that includes role, allowing same teacher with different roles
    add_index :teacher_class_assignments, %i[teacher_id school_class_id role], unique: true,
                                                                               name: :index_teacher_assignments_unique_with_role # rubocop:disable Layout/LineLength
  end

  def down
    # Restore old index
    remove_index :teacher_class_assignments, name: :index_teacher_assignments_unique_with_role, if_exists: true
    add_index :teacher_class_assignments, %i[teacher_id school_class_id], unique: true,
                                                                          name: :index_teacher_assignments_unique
  end
end
