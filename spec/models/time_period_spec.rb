require "rails_helper"

RSpec.describe TimePeriod, type: :model do
  describe "バリデーション" do
    it "名前と表示順がそろっていれば有効になる" do
      time_period = build(:time_period)

      expect(time_period).to be_valid
    end

    it "名前が空欄なら無効になる" do
      time_period = build(:time_period, name: "")

      expect(time_period).not_to be_valid
      expect(time_period.errors.of_kind?(:name, :blank)).to be true
    end

    it "表示順が未設定なら無効になる" do
      time_period = build(:time_period, position: nil)

      expect(time_period).not_to be_valid
      expect(time_period.errors.of_kind?(:position, :blank)).to be true
    end

    it "表示順が小数なら無効になる" do
      time_period = build(:time_period, position: 10.5)

      expect(time_period).not_to be_valid
      expect(
        time_period.errors.of_kind?(:position, :not_an_integer)
      ).to be true
    end

    it "表示順が数値ではない文字なら無効になる" do
      time_period = build(:time_period, position: "abc")

      expect(time_period).not_to be_valid
      expect(
        time_period.errors.of_kind?(:position, :not_a_number)
      ).to be true
    end
  end

  describe ".ordered" do
    it "表示順の小さい順に時間帯を取得する" do
      bedtime = create(:time_period, name: "就寝前", position: 40)
      evening = create(:time_period, name: "夕", position: 30)
      morning = create(:time_period, name: "朝", position: 10)
      noon = create(:time_period, name: "昼", position: 20)

      expect(described_class.ordered.to_a).to eq(
        [ morning, noon, evening, bedtime ]
      )
    end
  end

  describe "削除" do
    it "服薬タイミングで使用中の時間帯は削除できない" do
      time_period = create(:time_period)
      timing = create(:medication_timing, time_period: time_period)

      expect(time_period.destroy).to be false

      expect(TimePeriod.exists?(time_period.id)).to be true
      expect(MedicationTiming.exists?(timing.id)).to be true
      expect(
        time_period.errors.of_kind?(:base, :"restrict_dependent_destroy.has_many")
      ).to be true
    end

    it "使用されていない時間帯は削除できる" do
      time_period = create(:time_period)

      expect {
        time_period.destroy!
      }.to change(TimePeriod, :count).by(-1)
    end
  end
end
