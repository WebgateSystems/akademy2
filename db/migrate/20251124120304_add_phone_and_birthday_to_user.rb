class AddPhoneAndBirthdayToUser < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.date :birthdate
      t.string :phone
    end
  end
end
