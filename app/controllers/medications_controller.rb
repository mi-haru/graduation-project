class MedicationsController < ApplicationController
  layout "authenticated"

  before_action :authenticate_user!

  def index
    @medications = current_user.medications.order(start_date: :desc)
  end

  def new
    @medication = current_user.medications.build
    prepare_timing_form
  end

  def create
    @medication = current_user.medications.build(medication_params)
    prepare_timing_form

    build_medication_timings if timing_selection_valid?

    if @medication.errors.empty? && @medication.save
      redirect_to medications_path,
                  notice: t("medications.notices.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

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

  def timing_selection_valid?
    valid = true

    if @selected_time_period_ids.empty?
      @medication.errors.add(
        :base,
        t("medications.errors.time_period_required")
      )
      valid = false
    end

    unless MedicationTiming.meal_timings.key?(@meal_timing)
      @medication.errors.add(
        :base,
        t("medications.errors.meal_timing_invalid")
      )
      valid = false
    end

    valid_time_period_ids = @time_periods.map { |period| period.id.to_s }

    if (@selected_time_period_ids - valid_time_period_ids).any?
      @medication.errors.add(
        :base,
        t("medications.errors.time_period_invalid")
      )
      valid = false
    end

    valid
  end

  def build_medication_timings
    @selected_time_period_ids.each do |time_period_id|
      @medication.medication_timings.build(
        time_period_id: time_period_id,
        meal_timing: @meal_timing
      )
    end
  end
end
