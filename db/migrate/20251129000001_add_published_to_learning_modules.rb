class AddPublishedToLearningModules < ActiveRecord::Migration[8.0]
  def change
    add_column :learning_modules, :published, :boolean, null: false, default: false
    add_index :learning_modules, :published
  end
end
