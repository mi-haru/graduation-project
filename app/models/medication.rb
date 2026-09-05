class Medication < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :dosage, presence: true
  validates :start_date, presence: true
end
