# frozen_string_literal: true

class AddJoinTokenToSchoolClassesAndSchools < ActiveRecord::Migration[7.2]
  def up
    # Add join_token column to school_classes if it doesn't exist
    unless column_exists?(:school_classes, :join_token)
      add_column :school_classes, :join_token, :string
      add_index :school_classes, :join_token, unique: true
    end

    # Add join_token column to schools if it doesn't exist
    unless column_exists?(:schools, :join_token)
      add_column :schools, :join_token, :string
      add_index :schools, :join_token, unique: true
    end

    # Generate join tokens for existing records
    SchoolClass.find_each do |school_class|
      if school_class.join_token.blank?
        # Format: xxxxxxxx-xxxx-xxxx (first 3 segments of UUID)
        token = SecureRandom.uuid.split('-').first(3).join('-')
        school_class.update_column(:join_token, token)
      end
    end

    School.find_each do |school|
      if school.join_token.blank?
        # Format: xxxx-xxxx-xxxxxxxxxxxx (last 3 segments of UUID)
        token = SecureRandom.uuid.split('-').last(3).join('-')
        school.update_column(:join_token, token)
      end
    end
  end

  def down
    remove_index :school_classes, :join_token if index_exists?(:school_classes, :join_token)
    remove_column :school_classes, :join_token if column_exists?(:school_classes, :join_token)

    remove_index :schools, :join_token if index_exists?(:schools, :join_token)
    remove_column :schools, :join_token if column_exists?(:schools, :join_token)
  end
end
