class User < ApplicationRecord
  has_many :medications, dependent: :destroy
  has_many :hospitals, dependent: :destroy
  has_many :appointments, through: :hospitals

  devise :database_authenticatable, :registerable,
         :validatable

  validates :nickname, presence: true, length: { maximum: 50 }
end
