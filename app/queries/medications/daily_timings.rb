module Medications
  class DailyTimings
    def initialize(user:, date:)
      @user = user
      @date = date
    end

    def call
      MedicationTiming
        .joins(:medication, :time_period)
        .includes(:medication, :time_period)
        .where(medications: { user_id: @user.id })
        .where("medications.start_date <= ?", @date)
        .where(
          "medications.end_date IS NULL OR medications.end_date >= ?",
          @date
        )
        .order("time_periods.position ASC, time_periods.id ASC, medication_timings.id ASC")
        .to_a
    end
  end
end
