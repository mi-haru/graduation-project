class AppointmentsController < ApplicationController
  layout "authenticated"

  before_action :authenticate_user!

  def index
    @appointments = current_user.appointments
                                .includes(:hospital)
                                .order(:appointment_date, :appointment_time, :id)
  end

  def new
    @hospital = current_user.hospitals.build
    @appointment = @hospital.appointments.build
  end

  def create
    attributes = appointment_params
    hospital_name = attributes.delete(:hospital_name)

    @hospital = current_user.hospitals.find_or_initialize_by(
      name: hospital_name
    )
    @appointment = @hospital.appointments.build(attributes)

    hospital_valid = @hospital.valid?
    appointment_valid = @appointment.valid?

    unless hospital_valid && appointment_valid
      render :new, status: :unprocessable_content
      return
    end

    begin
      Appointment.transaction do
        @hospital.save!
        @appointment.save!
      end
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_content
      return
    end

    redirect_to appointments_path,
                notice: t("appointments.notices.created"),
                status: :see_other
  end

  private

  def appointment_params
    params.require(:appointment).permit(
      :hospital_name,
      :department,
      :appointment_date,
      :appointment_time
    )
  end
end
