class AddIconAndColorsToSubjects < ActiveRecord::Migration[8.0]
  def change
    change_table :subjects, bulk: true do |t|
      t.string :icon
      t.string :color_light
      t.string :color_dark
    end
  end
end
