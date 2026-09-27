FactoryBot.define do
  factory :medication_check do
    association :medication_timing

    check_date { Date.new(2026, 9, 1) }
  end
end
