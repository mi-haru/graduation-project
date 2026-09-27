module Medications
  class Save
    def initialize(medication:, attributes:, time_period_ids:, meal_timing:)
      @medication = medication
      @attributes = attributes
      @time_period_ids = time_period_ids
      @meal_timing = meal_timing
    end

    def call
      @medication.assign_attributes(@attributes)

      if @medication.new_record?
        create
      else
        update
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => error
      unless error.record.equal?(@medication)
        @medication.errors.add(:base, error.record.errors.full_messages.to_sentence)
      end
      false
    end

    private

    def create
      return false unless timing_selection_valid?

      @time_period_ids.each do |time_period_id|
        @medication.medication_timings.build(
          time_period_id: time_period_id,
          meal_timing: @meal_timing
        )
      end

      @medication.save
    end

    def update
      medication_valid = @medication.valid?
      timing_valid = timing_selection_valid?
      return false unless medication_valid && timing_valid

      Medication.transaction do
        @medication.save!
        sync_medication_timings!
      end

      true
    end

    def timing_selection_valid?
      valid = true

      if @time_period_ids.empty?
        add_timing_error("time_period_required")
        valid = false
      end

      unless MedicationTiming.meal_timings.key?(@meal_timing)
        add_timing_error("meal_timing_invalid")
        valid = false
      end

      valid_ids = TimePeriod.pluck(:id).map(&:to_s)

      if (@time_period_ids - valid_ids).any?
        add_timing_error("time_period_invalid")
        valid = false
      end

      valid
    end

    def add_timing_error(key)
      @medication.errors.add(:base, I18n.t("medications.errors.#{key}"))
    end

    def sync_medication_timings!
      existing_timings = @medication.medication_timings.to_a

      existing_timings.each do |timing|
        if @time_period_ids.include?(timing.time_period_id.to_s)
          timing.update!(meal_timing: @meal_timing)
        else
          timing.destroy!
        end
      end

      existing_ids = existing_timings.map { |timing| timing.time_period_id.to_s }

      (@time_period_ids - existing_ids).each do |time_period_id|
        @medication.medication_timings.create!(
          time_period_id: time_period_id,
          meal_timing: @meal_timing
        )
      end
    end
  end
end
