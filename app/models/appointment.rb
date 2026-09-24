class Appointment < ApplicationRecord
  belongs_to :hospital

  validates :appointment_date, presence: true
end
