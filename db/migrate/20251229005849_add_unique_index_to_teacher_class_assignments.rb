# frozen_string_literal: true

class AddUniqueIndexToTeacherClassAssignments < ActiveRecord::Migration[8.1]
  def change
    # First, remove any existing duplicates (keep only the first one by created_at)
    reversible do |dir|
      dir.up do
        # Use ROW_NUMBER() which works with UUIDs
        execute <<~SQL.squish
          DELETE FROM teacher_class_assignments
          WHERE id IN (
            SELECT id FROM (
              SELECT id,
                     ROW_NUMBER() OVER (
                       PARTITION BY teacher_id, school_class_id
                       ORDER BY created_at ASC
                     ) AS row_num
              FROM teacher_class_assignments
            ) sub
            WHERE row_num > 1
          )
        SQL
      end
    end

    # Add unique index to prevent future duplicates
    add_index :teacher_class_assignments,
              %i[teacher_id school_class_id],
              unique: true,
              name: 'index_teacher_class_assignments_unique'
  end
end
