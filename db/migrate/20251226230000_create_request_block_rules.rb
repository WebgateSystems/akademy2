class CreateRequestBlockRules < ActiveRecord::Migration[8.1]
  def change
    create_table :request_block_rules, id: :uuid do |t|
      t.string :rule_type, null: false # ip | cidr | user_agent
      t.string :value, null: false
      t.boolean :enabled, null: false, default: true
      t.uuid :created_by_id
      t.text :note

      t.timestamps
    end

    add_index :request_block_rules, %i[rule_type value], unique: true
    add_index :request_block_rules, :enabled
    add_index :request_block_rules, :created_by_id
  end
end
