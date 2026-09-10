class CreateMedicationChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :medication_checks do |t|
      t.references :medication_timing, null: false, foreign_key: true
      t.date :check_date, null: false

      t.timestamps
    end

    add_index :medication_checks,
              [ :medication_timing_id, :check_date ],
              unique: true
  end
end
