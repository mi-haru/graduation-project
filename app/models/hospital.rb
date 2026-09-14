class Hospital < ApplicationRecord
  belongs_to :user
  has_many :appointments, dependent: :destroy

  validates :name, presence: true
end
