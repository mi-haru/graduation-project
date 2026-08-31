class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable

  validates :nickname, presence: true, length: { maximum: 50 }
end
