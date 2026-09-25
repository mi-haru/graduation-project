FactoryBot.define do
  factory :hospital do
    association :user

    name { "テスト病院" }
  end
end
