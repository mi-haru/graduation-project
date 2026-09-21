class HomeController < ApplicationController
  layout "authenticated"

  before_action :authenticate_user!

  def index
    now = Time.current
    @today = now.to_date

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

    appointments = current_user.appointments
      .includes(:hospital)
      .where("appointments.appointment_date >= ?", @today)
      .to_a

    current_time = now.strftime("%H:%M:%S")

    upcoming_appointments = appointments.select do |appointment|
      appointment.appointment_date > @today ||
        appointment.appointment_time.nil? ||
        appointment.appointment_time.strftime("%H:%M:%S") >= current_time
    end

    @next_appointment = upcoming_appointments.min_by do |appointment|
      [
        appointment.appointment_date,
        appointment.appointment_time&.strftime("%H:%M:%S") || "24:00:00",
        appointment.id
      ]
    end
  end
end
