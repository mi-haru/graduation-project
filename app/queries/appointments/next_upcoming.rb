module Appointments
  class NextUpcoming
    def initialize(user:, now:)
      @user = user
      @now = now
    end

    def call
      today = @now.to_date
      current_time = @now.strftime("%H:%M:%S")

      appointments = @user.appointments
        .includes(:hospital)
        .where("appointments.appointment_date >= ?", today)
        .to_a

      upcoming = appointments.select do |appointment|
        appointment.appointment_date > today ||
          appointment.appointment_time.nil? ||
          appointment.appointment_time.strftime("%H:%M:%S") >= current_time
      end

      upcoming.min_by do |appointment|
        [
          appointment.appointment_date,
          appointment.appointment_time&.strftime("%H:%M:%S") || "24:00:00",
          appointment.id
        ]
      end
    end
  end
end
