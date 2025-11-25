class CreateJwtRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :jwt_refresh_tokens, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string   :token_digest, null: false
      t.datetime :exp,          null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :jwt_refresh_tokens, :token_digest, unique: true
    add_index :jwt_refresh_tokens, %i[user_id exp], name: :index_jwt_tokens_on_user_and_exp
  end
end
