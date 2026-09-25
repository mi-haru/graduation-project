require "rails_helper"

RSpec.describe Hospital, type: :model do
  describe "バリデーション" do
    it "ユーザーと医療機関名がそろっていれば有効になる" do
      hospital = build(:hospital)

      expect(hospital).to be_valid
    end

    it "ユーザーが紐づいていなければ無効になる" do
      hospital = build(:hospital, user: nil)

      expect(hospital).not_to be_valid
      expect(hospital.errors.of_kind?(:user, :blank)).to be true
    end

    it "医療機関名が空欄なら無効になる" do
      hospital = build(:hospital, name: "")

      expect(hospital).not_to be_valid
      expect(hospital.errors.of_kind?(:name, :blank)).to be true
    end
  end

  describe "関連付け" do
    it "自分に紐づく受診予定だけを取得できる" do
      hospital = create(:hospital)
      first_appointment = create(:appointment, hospital: hospital)
      second_appointment = create(:appointment, hospital: hospital)
      create(:appointment)

      expect(hospital.appointments).to contain_exactly(
        first_appointment,
        second_appointment
      )
    end
  end

  describe "関連データの削除" do
    it "医療機関を削除すると紐づく受診予定も削除される" do
      hospital = create(:hospital)
      first_appointment = create(:appointment, hospital: hospital)
      second_appointment = create(:appointment, hospital: hospital)
      other_appointment = create(:appointment)

      hospital.destroy!

      expect(Hospital.exists?(hospital.id)).to be false
      expect(Appointment.exists?(first_appointment.id)).to be false
      expect(Appointment.exists?(second_appointment.id)).to be false

      expect(Appointment.exists?(other_appointment.id)).to be true
      expect(Hospital.exists?(other_appointment.hospital_id)).to be true
    end
  end
end
