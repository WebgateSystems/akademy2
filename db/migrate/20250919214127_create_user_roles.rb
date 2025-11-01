class CreateUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_roles, id: :uuid do |t|
      t.references :user,   null: false, type: :uuid, foreign_key: true
      t.references :role,   null: false, type: :uuid, foreign_key: true
      t.references :school,              type: :uuid, foreign_key: true
      t.timestamps
    end
    add_index :user_roles, [ :user_id, :role_id, :school_id ], unique: true, name: :index_user_roles_unique_triplet
  end
end
