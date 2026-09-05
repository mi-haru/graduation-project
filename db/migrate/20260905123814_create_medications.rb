class CreateMedications < ActiveRecord::Migration[8.1]
  def change
    create_table :medications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :dosage, null: false
      t.date :start_date, null: false
      t.date :end_date

      t.timestamps
    end
  end
end
