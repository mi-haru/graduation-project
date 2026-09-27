require "rails_helper"

RSpec.describe Medication, type: :model do
  describe "バリデーション" do
    it "必要な情報がそろっていれば有効になる" do
      medication = build(:medication)

      expect(medication).to be_valid
    end

    it "薬名が空欄なら無効になる" do
      medication = build(:medication, name: "")

      expect(medication).not_to be_valid
      expect(medication.errors.of_kind?(:name, :blank)).to be true
    end

    it "用量が空欄なら無効になる" do
      medication = build(:medication, dosage: "")

      expect(medication).not_to be_valid
      expect(medication.errors.of_kind?(:dosage, :blank)).to be true
    end

    it "服薬開始日が未設定なら無効になる" do
      medication = build(:medication, start_date: nil)

      expect(medication).not_to be_valid
      expect(medication.errors.of_kind?(:start_date, :blank)).to be true
    end

        it "服薬終了日が未設定でも有効になる" do
      medication = build(:medication, end_date: nil)

      expect(medication).to be_valid
    end

    it "服薬終了日が開始日と同じなら有効になる" do
      medication = build(
        :medication,
        start_date: Date.new(2026, 9, 1),
        end_date: Date.new(2026, 9, 1)
      )

      expect(medication).to be_valid
    end

    it "服薬終了日が開始日より後なら有効になる" do
      medication = build(
        :medication,
        start_date: Date.new(2026, 9, 1),
        end_date: Date.new(2026, 9, 2)
      )

      expect(medication).to be_valid
    end

    it "服薬終了日が開始日より前なら無効になる" do
      medication = build(
        :medication,
        start_date: Date.new(2026, 9, 1),
        end_date: Date.new(2026, 8, 31)
      )

      expect(medication).not_to be_valid
      expect(
        medication.errors.of_kind?(:end_date, :before_start_date)
      ).to be true
    end

    it "ユーザーが紐づいていなければ無効になる" do
      medication = build(:medication, user: nil)

      expect(medication).not_to be_valid
      expect(medication.errors.of_kind?(:user, :blank)).to be true
    end
  end

  describe "関連データの削除" do
    it "薬を削除すると関連する服薬タイミングとチェックも削除される" do
      medication = create(:medication)
      timing = create(:medication_timing, medication: medication)
      check = create(:medication_check, medication_timing: timing)
      other_check = create(:medication_check)

      medication.destroy!

      expect(Medication.exists?(medication.id)).to be false
      expect(MedicationTiming.exists?(timing.id)).to be false
      expect(MedicationCheck.exists?(check.id)).to be false

      expect(
        MedicationTiming.exists?(other_check.medication_timing_id)
      ).to be true
      expect(MedicationCheck.exists?(other_check.id)).to be true

      expect(TimePeriod.exists?(timing.time_period_id)).to be true
    end
  end
end
