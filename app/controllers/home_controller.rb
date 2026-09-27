class HomeController < ApplicationController
  layout "authenticated"

  before_action :authenticate_user!

  def index
    now = Time.current
    @today = now.to_date

    @medication_timings = Medications::DailyTimings.new(
      user: current_user,
      date: @today
    ).call

    @timings_by_time_period =
      @medication_timings.group_by(&:time_period)

    @checked_timing_ids = MedicationCheck
      .where(
        medication_timing_id: @medication_timings.map(&:id),
        check_date: @today
      )
      .pluck(:medication_timing_id)

    @next_appointment = Appointments::NextUpcoming.new(
      user: current_user,
      now: now
    ).call
  end
end
