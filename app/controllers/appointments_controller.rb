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

  def edit
    @hospital = @appointment.hospital
  end

  def update
    attributes = appointment_params
    hospital_name = attributes.delete(:hospital_name)

    @hospital = current_user.hospitals.find_or_initialize_by(
      name: hospital_name
    )

    @appointment.assign_attributes(attributes)
    @appointment.hospital = @hospital

    hospital_valid = @hospital.valid?
    appointment_valid = @appointment.valid?

    unless hospital_valid && appointment_valid
      render :edit, status: :unprocessable_content
      return
    end

    begin
      Appointment.transaction do
        @hospital.save!
        @appointment.save!
      end
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_content
      return
    end

    redirect_to appointments_path,
                notice: t("appointments.notices.updated"),
                status: :see_other
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
end
