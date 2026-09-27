class MedicationsController < ApplicationController
  layout "authenticated"

  before_action :authenticate_user!
  before_action :set_medication, only: %i[show edit update destroy]

  def index
    @medications = current_user.medications
                               .includes(medication_timings: :time_period)
                               .order(start_date: :desc)
  end

  def new
    @medication = current_user.medications.build
    prepare_timing_form
  end

  def create
    @medication = current_user.medications.build
    prepare_timing_form

    if save_medication
      redirect_to medications_path,
                  notice: t("medications.notices.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    redirect_to edit_medication_path(@medication)
  end

  def edit
    @time_periods = TimePeriod.ordered

    timings = @medication.medication_timings.to_a

    @selected_time_period_ids =
      timings.map { |timing| timing.time_period_id.to_s }

    @meal_timing =
      timings.first&.meal_timing || "unspecified"
  end

  def update
    prepare_timing_form

    if save_medication
      redirect_to medications_path,
                  notice: t("medications.notices.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @medication.destroy
      redirect_to medications_path,
                  notice: t("medications.notices.destroyed"),
                  status: :see_other
    else
      redirect_to edit_medication_path(@medication),
                  alert: t("medications.errors.destroy_failed"),
                  status: :see_other
    end
  end

  private

  def set_medication
    @medication = current_user.medications.find(params[:id])
  end

  def medication_params
    params.require(:medication).permit(
      :name,
      :dosage,
      :start_date,
      :end_date
    )
  end

  def prepare_timing_form
    @time_periods = TimePeriod.ordered
    @selected_time_period_ids =
      Array(params.dig(:medication, :time_period_ids))
        .reject(&:blank?)
        .uniq
    @meal_timing =
      params.dig(:medication, :meal_timing).presence || "unspecified"
  end

  def save_medication
    Medications::Save.new(
      medication: @medication,
      attributes: medication_params,
      time_period_ids: @selected_time_period_ids,
      meal_timing: @meal_timing
    ).call
  end
end
