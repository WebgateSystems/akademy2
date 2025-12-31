# frozen_string_literal: true

class RemoveDuplicateUniqueIndexFromTeacherClassAssignments < ActiveRecord::Migration[8.1]
  def up
    # Remove the duplicate unique index that doesn't include role
    # This index conflicts with index_teacher_assignments_unique_with_role
    # and prevents teachers from being assigned to the same class in different roles
    remove_index :teacher_class_assignments,
                 name: 'index_teacher_class_assignments_unique',
                 if_exists: true
  end

  def down
    # Restore the index if needed (though it conflicts with the role-based index)
    add_index :teacher_class_assignments,
              %i[teacher_id school_class_id],
              unique: true,
              name: 'index_teacher_class_assignments_unique',
              if_not_exists: true
  end
end
