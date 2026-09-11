class MedicationTiming < ApplicationRecord
  belongs_to :medication
  belongs_to :time_period

  has_many :medication_checks, dependent: :destroy

  enum :meal_timing, {
    unspecified: 0,
    before_meal: 1,
    after_meal: 2,
    between_meals: 3,
    immediately_before_meal: 4
  }

  validates :meal_timing, presence: true
  validates :time_period_id,
            uniqueness: { scope: :medication_id }
end
