module MedicationsHelper
  def medication_time_periods_text(medication)
    timings = ordered_medication_timings(medication)
    return t("medications.index.not_set") if timings.empty?

    timings.map { |timing| timing.time_period.name }.join("・")
  end

  def medication_meal_timings_text(medication)
    timings = ordered_medication_timings(medication)
    return t("medications.index.not_set") if timings.empty?

    timings.map do |timing|
      t("enums.medication_timing.meal_timing.#{timing.meal_timing}")
    end.uniq.join("・")
  end

  private

  def ordered_medication_timings(medication)
    medication.medication_timings.sort_by do |timing|
      [ timing.time_period.position, timing.time_period.id ]
    end
  end
end
