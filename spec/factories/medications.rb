FactoryBot.define do
  factory :medication do
    association :user

    name { "テスト用のお薬" }
    dosage { "1錠" }
    start_date { Date.new(2026, 9, 1) }
    end_date { nil }
  end
end
