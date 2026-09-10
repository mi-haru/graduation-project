class MedicationCheck < ApplicationRecord
  belongs_to :medication_timing

  validates :check_date, presence: true
  validates :check_date,
            uniqueness: { scope: :medication_timing_id }
end
