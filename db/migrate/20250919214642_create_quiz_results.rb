class CreateQuizResults < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_results, id: :uuid do |t|
      t.references :user,            null: false, type: :uuid, foreign_key: true
      t.references :learning_module, null: false, type: :uuid, foreign_key: true
      t.integer  :score,  null: false
      t.boolean  :passed, null: false
      t.jsonb    :details, null: false, default: {}
      t.datetime :completed_at, null: false
      t.timestamps
    end
    add_index :quiz_results, %i[user_id learning_module_id], unique: true,
                                                             name: :index_quiz_results_unique_user_module
  end
end
