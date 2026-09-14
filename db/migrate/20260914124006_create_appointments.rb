class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :hospital, null: false, foreign_key: true
      t.string :department
      t.date :appointment_date, null: false
      t.time :appointment_time

      t.timestamps
    end
  end
end
