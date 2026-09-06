class Medication < ApplicationRecord
  belongs_to :user

  has_many :medication_timings, dependent: :destroy
  has_many :time_periods, through: :medication_timings

  validates :name, presence: true
  validates :dosage, presence: true
  validates :start_date, presence: true
  validate :end_date_cannot_be_before_start_date

  private

  def end_date_cannot_be_before_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, :before_start_date)
  end
end
