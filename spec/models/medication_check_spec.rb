require "rails_helper"

RSpec.describe MedicationCheck, type: :model do
  describe "バリデーション" do
    it "服薬タイミングとチェック日がそろっていれば有効になる" do
      medication_check = build(:medication_check)

      expect(medication_check).to be_valid
    end

    it "服薬タイミングが紐づいていなければ無効になる" do
      medication_check = build(:medication_check, medication_timing: nil)

      expect(medication_check).not_to be_valid
      expect(
        medication_check.errors.of_kind?(:medication_timing, :blank)
      ).to be true
    end

    it "チェック日が未設定なら無効になる" do
      medication_check = build(:medication_check, check_date: nil)

      expect(medication_check).not_to be_valid
      expect(
        medication_check.errors.of_kind?(:check_date, :blank)
      ).to be true
    end

    it "同じ服薬タイミングと日付では重複登録できない" do
      existing_check = create(:medication_check)

      duplicate_check = build(
        :medication_check,
        medication_timing: existing_check.medication_timing,
        check_date: existing_check.check_date
      )

      expect(duplicate_check).not_to be_valid
      expect(
        duplicate_check.errors.of_kind?(:check_date, :taken)
      ).to be true
    end

    it "同じ服薬タイミングでも日付が異なれば登録できる" do
      existing_check = create(:medication_check)

      another_check = build(
        :medication_check,
        medication_timing: existing_check.medication_timing,
        check_date: existing_check.check_date + 1.day
      )

      expect(another_check).to be_valid
    end

    it "同じ日付でも服薬タイミングが異なれば登録できる" do
      existing_check = create(:medication_check)

      another_check = build(
        :medication_check,
        medication_timing: create(:medication_timing),
        check_date: existing_check.check_date
      )

      expect(another_check).to be_valid
    end
  end
end
