class TimePeriod < ApplicationRecord
  has_many :medication_timings, dependent: :restrict_with_error
  has_many :medications, through: :medication_timings

  validates :name, presence: true
  validates :position, presence: true,
                       numericality: { only_integer: true }

  scope :ordered, -> { order(:position) }
end
