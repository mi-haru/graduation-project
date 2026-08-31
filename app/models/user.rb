class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :validatable

  validates :nickname, presence: true, length: { maximum: 50 }
end
