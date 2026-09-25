FactoryBot.define do
  factory :medication_timing do
    association :medication
    association :time_period

    meal_timing { :after_meal }
  end
end
