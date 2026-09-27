class AppointmentsController < ApplicationController
  layout "authenticated"

  before_action :authenticate_user!
  before_action :set_appointment, only: %i[edit update destroy]

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
    @appointment = Appointment.new

    if save_appointment
      redirect_to appointments_path,
                  notice: t("appointments.notices.created"),
                  status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @hospital = @appointment.hospital
  end

  def update
    if save_appointment
      redirect_to appointments_path,
                  notice: t("appointments.notices.updated"),
                  status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @appointment.destroy
      redirect_to appointments_path,
                  notice: t("appointments.notices.destroyed"),
                  status: :see_other
    else
      redirect_to edit_appointment_path(@appointment),
                  alert: t("appointments.errors.destroy_failed"),
                  status: :see_other
    end
  end

  private

  def set_appointment
    @appointment = current_user.appointments.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(
      :hospital_name,
      :department,
      :appointment_date,
      :appointment_time
    )
  end

  def save_appointment
    service = Appointments::Save.new(
      user: current_user,
      appointment: @appointment,
      attributes: appointment_params
    )

    success = service.call
    @hospital = service.hospital
    success
  end
end
