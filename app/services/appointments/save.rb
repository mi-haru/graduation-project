module Appointments
  class Save
    attr_reader :hospital

    def initialize(user:, appointment:, attributes:)
      @user = user
      @appointment = appointment
      @attributes = attributes.dup
    end

    def call
      hospital_name = @attributes.delete(:hospital_name)

      @hospital = @user.hospitals.find_or_initialize_by(
        name: hospital_name
      )

      @appointment.assign_attributes(@attributes)
      @appointment.hospital = @hospital

      hospital_valid = @hospital.valid?
      appointment_valid = @appointment.valid?
      return false unless hospital_valid && appointment_valid

      Appointment.transaction do
        @hospital.save!
        @appointment.save!
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end
