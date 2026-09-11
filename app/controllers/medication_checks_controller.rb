class MedicationChecksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medication_timing
  before_action :set_check_date

  def create
    @medication_timing.medication_checks.find_or_create_by!(
      check_date: @check_date
    )

    redirect_to home_path, status: :see_other
  end

  def destroy
    check = @medication_timing.medication_checks.find_by(
      check_date: @check_date
    )

    check&.destroy!

    redirect_to home_path, status: :see_other
  end

  private

  def set_medication_timing
    @medication_timing = MedicationTiming
      .joins(:medication)
      .where(medications: { user_id: current_user.id })
      .find(params[:medication_timing_id])
  end

  def set_check_date
    @check_date = Date.current
  end
end
