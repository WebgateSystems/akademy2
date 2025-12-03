# frozen_string_literal: true

class UpdateForeignKeysCascade < ActiveRecord::Migration[8.1]
  def up
    # Remove existing foreign keys that need to be changed
    remove_foreign_key :events, :users if foreign_key_exists?(:events, :users)
    remove_foreign_key :student_class_enrollments, :school_classes if foreign_key_exists?(:student_class_enrollments,
                                                                                          :school_classes)
    remove_foreign_key :teacher_class_assignments, :school_classes if foreign_key_exists?(:teacher_class_assignments,
                                                                                          :school_classes)

    # Remove foreign keys for notifications that need CASCADE
    remove_foreign_key :notifications, :users if foreign_key_exists?(:notifications, :users)
    remove_foreign_key :notifications, column: :read_by_user_id if foreign_key_exists?(:notifications,
                                                                                       column: :read_by_user_id)

    # Remove foreign keys for school-related tables that need CASCADE
    remove_foreign_key :school_classes, :schools if foreign_key_exists?(:school_classes, :schools)
    remove_foreign_key :academic_years, :schools if foreign_key_exists?(:academic_years, :schools)
    remove_foreign_key :subjects, :schools if foreign_key_exists?(:subjects, :schools)
    remove_foreign_key :subscriptions, :schools if foreign_key_exists?(:subscriptions, :schools)
    remove_foreign_key :teacher_school_enrollments, :schools if foreign_key_exists?(:teacher_school_enrollments,
                                                                                    :schools)
    remove_foreign_key :user_roles, :schools if foreign_key_exists?(:user_roles, :schools)
    remove_foreign_key :users, :schools if foreign_key_exists?(:users, :schools)
    remove_foreign_key :notifications, :schools if foreign_key_exists?(:notifications, :schools)
    remove_foreign_key :events, :schools if foreign_key_exists?(:events, :schools)

    # Add foreign keys with ON DELETE CASCADE

    # Events: CASCADE when user is deleted
    add_foreign_key :events, :users, on_delete: :cascade

    # Notifications: CASCADE when user is deleted
    add_foreign_key :notifications, :users, on_delete: :cascade

    # Notifications: CASCADE when read_by_user is deleted
    add_foreign_key :notifications, :users, column: :read_by_user_id, on_delete: :cascade

    # School classes: CASCADE when school is deleted
    add_foreign_key :school_classes, :schools, on_delete: :cascade

    # Student class enrollments: CASCADE when class is deleted (students remain)
    add_foreign_key :student_class_enrollments, :school_classes, on_delete: :cascade

    # Teacher class assignments: CASCADE when class is deleted
    add_foreign_key :teacher_class_assignments, :school_classes, on_delete: :cascade

    # Academic years: CASCADE when school is deleted
    add_foreign_key :academic_years, :schools, on_delete: :cascade

    # Subjects: CASCADE when school is deleted
    add_foreign_key :subjects, :schools, on_delete: :cascade

    # Subscriptions: CASCADE when school is deleted
    add_foreign_key :subscriptions, :schools, on_delete: :cascade

    # Teacher school enrollments: CASCADE when school is deleted
    add_foreign_key :teacher_school_enrollments, :schools, on_delete: :cascade

    # User roles: CASCADE when school is deleted
    add_foreign_key :user_roles, :schools, on_delete: :cascade

    # Users: CASCADE when school is deleted (all users associated with school)
    add_foreign_key :users, :schools, on_delete: :cascade

    # Notifications: CASCADE when school is deleted
    add_foreign_key :notifications, :schools, on_delete: :cascade

    # Events: CASCADE when school is deleted
    add_foreign_key :events, :schools, on_delete: :cascade
  end

  def down
    # Remove CASCADE foreign keys
    remove_foreign_key :events, :users if foreign_key_exists?(:events, :users)
    remove_foreign_key :notifications, :users if foreign_key_exists?(:notifications, :users)
    remove_foreign_key :notifications, column: :read_by_user_id if foreign_key_exists?(:notifications,
                                                                                       column: :read_by_user_id)
    remove_foreign_key :school_classes, :schools if foreign_key_exists?(:school_classes, :schools)
    remove_foreign_key :student_class_enrollments, :school_classes if foreign_key_exists?(:student_class_enrollments,
                                                                                          :school_classes)
    remove_foreign_key :teacher_class_assignments, :school_classes if foreign_key_exists?(:teacher_class_assignments,
                                                                                          :school_classes)
    remove_foreign_key :academic_years, :schools if foreign_key_exists?(:academic_years, :schools)
    remove_foreign_key :subjects, :schools if foreign_key_exists?(:subjects, :schools)
    remove_foreign_key :subscriptions, :schools if foreign_key_exists?(:subscriptions, :schools)
    remove_foreign_key :teacher_school_enrollments, :schools if foreign_key_exists?(:teacher_school_enrollments,
                                                                                    :schools)
    remove_foreign_key :user_roles, :schools if foreign_key_exists?(:user_roles, :schools)
    remove_foreign_key :users, :schools if foreign_key_exists?(:users, :schools)
    remove_foreign_key :notifications, :schools if foreign_key_exists?(:notifications, :schools)
    remove_foreign_key :events, :schools if foreign_key_exists?(:events, :schools)

    # Restore original foreign keys without CASCADE
    add_foreign_key :events, :users
    add_foreign_key :notifications, :users
    add_foreign_key :notifications, :users, column: :read_by_user_id
    add_foreign_key :school_classes, :schools
    add_foreign_key :student_class_enrollments, :school_classes
    add_foreign_key :teacher_class_assignments, :school_classes
    add_foreign_key :academic_years, :schools
    add_foreign_key :subjects, :schools
    add_foreign_key :subscriptions, :schools
    add_foreign_key :teacher_school_enrollments, :schools
    add_foreign_key :user_roles, :schools
    add_foreign_key :users, :schools
    add_foreign_key :notifications, :schools
    add_foreign_key :events, :schools
  end
end
