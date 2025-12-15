# frozen_string_literal: true

class AddDescriptionToSubjects < ActiveRecord::Migration[8.0]
  def change
    add_column :subjects, :description, :string
  end
end
