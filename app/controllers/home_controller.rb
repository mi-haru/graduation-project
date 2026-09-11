class HomeController < ApplicationController
  layout "authenticated"

  before_action :authenticate_user!

  def index
    @today = Date.current

    @medication_timings = MedicationTiming
      .joins(:medication, :time_period)
      .includes(:medication, :time_period)
      .where(medications: { user_id: current_user.id })
      .where("medications.start_date <= ?", @today)
      .where(
        "medications.end_date IS NULL OR medications.end_date >= ?",
        @today
      )
      .order("time_periods.position ASC, time_periods.id ASC, medication_timings.id ASC")
      .to_a

    @timings_by_time_period =
      @medication_timings.group_by(&:time_period)

    @checked_timing_ids = MedicationCheck
      .where(
        medication_timing_id: @medication_timings.map(&:id),
        check_date: @today
      )
      .pluck(:medication_timing_id)
  end
end
