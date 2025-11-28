# frozen_string_literal: true

class CreateAcademicYears < ActiveRecord::Migration[8.0]
  def change
    create_table :academic_years, id: :uuid do |t|
      t.references :school, null: false, type: :uuid, foreign_key: true
      t.string :year, null: false # e.g., "2024/2025", "2025/2026"
      t.boolean :is_current, default: false, null: false
      t.date :started_at
      t.date :ended_at
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :academic_years, %i[school_id year], unique: true, name: :index_academic_years_on_school_and_year
    add_index :academic_years, %i[school_id is_current], name: :index_academic_years_on_school_and_current
  end
end
