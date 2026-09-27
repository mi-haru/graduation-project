require "rails_helper"

RSpec.describe MedicationTiming, type: :model do
  describe "バリデーション" do
    it "薬・時間帯・食事タイミングがそろっていれば有効になる" do
      medication_timing = build(:medication_timing)

      expect(medication_timing).to be_valid
    end

    it "薬が紐づいていなければ無効になる" do
      medication_timing = build(:medication_timing, medication: nil)

      expect(medication_timing).not_to be_valid
      expect(medication_timing.errors.of_kind?(:medication, :blank)).to be true
    end

    it "時間帯が紐づいていなければ無効になる" do
      medication_timing = build(:medication_timing, time_period: nil)

      expect(medication_timing).not_to be_valid
      expect(medication_timing.errors.of_kind?(:time_period, :blank)).to be true
    end

    it "食事タイミングが未設定なら無効になる" do
      medication_timing = build(:medication_timing, meal_timing: nil)

      expect(medication_timing).not_to be_valid
      expect(medication_timing.errors.of_kind?(:meal_timing, :blank)).to be true
    end

    it "同じ薬に同じ時間帯を重複登録できない" do
      existing_timing = create(:medication_timing)

      duplicate_timing = build(
        :medication_timing,
        medication: existing_timing.medication,
        time_period: existing_timing.time_period
      )

      expect(duplicate_timing).not_to be_valid
      expect(
        duplicate_timing.errors.of_kind?(:time_period_id, :taken)
      ).to be true
    end

    it "別の薬なら同じ時間帯を登録できる" do
      existing_timing = create(:medication_timing)

      another_timing = build(
        :medication_timing,
        medication: create(:medication),
        time_period: existing_timing.time_period
      )

      expect(another_timing).to be_valid
    end

    it "同じ薬でも別の時間帯なら登録できる" do
      existing_timing = create(:medication_timing)

      another_timing = build(
        :medication_timing,
        medication: existing_timing.medication,
        time_period: create(:time_period, name: "夕", position: 30)
      )

      expect(another_timing).to be_valid
    end

    it "食事タイミングのenumが定義どおりである" do
      expect(described_class.meal_timings).to eq(
        "unspecified" => 0,
        "before_meal" => 1,
        "after_meal" => 2,
        "between_meals" => 3,
        "immediately_before_meal" => 4
      )
    end

    it "食事タイミングが指定なしでも有効になる" do
      medication_timing = build(
        :medication_timing,
        meal_timing: :unspecified
      )

      expect(medication_timing).to be_valid
    end
  end

  describe "関連データの削除" do
    it "服薬タイミングを削除すると関連するチェックも削除される" do
      timing = create(:medication_timing)
      check = create(:medication_check, medication_timing: timing)
      other_check = create(:medication_check)

      timing.destroy!

      expect(MedicationTiming.exists?(timing.id)).to be false
      expect(MedicationCheck.exists?(check.id)).to be false
      expect(MedicationCheck.exists?(other_check.id)).to be true
    end
  end
end
