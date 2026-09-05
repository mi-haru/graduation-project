class User < ApplicationRecord
  has_many :medications, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :validatable

  validates :nickname, presence: true, length: { maximum: 50 }
end
