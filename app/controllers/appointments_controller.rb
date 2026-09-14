class AppointmentsController < ApplicationController
  layout "authenticated"

  before_action :authenticate_user!

  def index
    @appointments = current_user.appointments
                                .includes(:hospital)
                                .order(:appointment_date, :appointment_time, :id)
  end
end
