class AddSlugToLearningModules < ActiveRecord::Migration[8.0]
  def change
    add_column :learning_modules, :slug, :string
    add_index :learning_modules, :slug, unique: true
  end
end
