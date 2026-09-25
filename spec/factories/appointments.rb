FactoryBot.define do
  factory :appointment do
    association :hospital

    department { "内科" }
    appointment_date { Date.new(2026, 10, 1) }
    appointment_time { "10:30" }
  end
end
