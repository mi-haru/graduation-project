require "rails_helper"

RSpec.describe Appointment, type: :model do
  describe "バリデーション" do
    it "必要な情報がそろっていれば有効になる" do
      appointment = build(:appointment)

      expect(appointment).to be_valid
    end

    it "医療機関が紐づいていなければ無効になる" do
      appointment = build(:appointment, hospital: nil)

      expect(appointment).not_to be_valid
      expect(appointment.errors.of_kind?(:hospital, :blank)).to be true
    end

    it "受診日が未設定なら無効になる" do
      appointment = build(:appointment, appointment_date: nil)

      expect(appointment).not_to be_valid
      expect(
        appointment.errors.of_kind?(:appointment_date, :blank)
      ).to be true
    end

    it "診療科が空欄でも有効になる" do
      appointment = build(:appointment, department: "")

      expect(appointment).to be_valid
    end

    it "受診時間が未設定でも有効になる" do
      appointment = build(:appointment, appointment_time: nil)

      expect(appointment).to be_valid
    end
  end

  describe "削除" do
    it "受診予定を削除しても医療機関とほかの予定は残る" do
      hospital = create(:hospital)
      appointment = create(:appointment, hospital: hospital)
      other_appointment = create(:appointment, hospital: hospital)

      appointment.destroy!

      expect(Appointment.exists?(appointment.id)).to be false
      expect(Hospital.exists?(hospital.id)).to be true
      expect(Appointment.exists?(other_appointment.id)).to be true
    end
  end
end
