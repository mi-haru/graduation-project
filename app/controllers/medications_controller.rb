class MedicationsController < ApplicationController
  layout "authenticated"

  before_action :authenticate_user!

  def index
    @medications = current_user.medications.order(start_date: :desc)
  end
end
