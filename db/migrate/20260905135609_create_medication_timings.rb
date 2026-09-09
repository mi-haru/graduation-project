class CreateMedicationTimings < ActiveRecord::Migration[8.1]
  def change
    create_table :medication_timings do |t|
      t.references :medication, null: false, foreign_key: true
      t.references :time_period, null: false, foreign_key: true
      t.integer :meal_timing, null: false

      t.timestamps
    end

    add_index :medication_timings,
              [ :medication_id, :time_period_id ],
              unique: true
  end
end
