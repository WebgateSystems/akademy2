class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :school, null: false, type: :uuid, foreign_key: true
      t.references :plan,   null: false, type: :uuid, foreign_key: true
      t.date    :starts_on,  null: false
      t.date    :expires_on, null: false
      t.string  :status,     null: false
      t.string  :external_ref
      t.timestamps
    end
    add_index :subscriptions, %i[school_id plan_id starts_on], name: :index_subs_on_school_plan_start
  end
end
