require "rails_helper"

RSpec.describe "服薬チェック", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:medication) { create(:medication, user: user) }
  let(:timing) { create(:medication_timing, medication: medication) }
  let(:check_path) { medication_timing_medication_check_path(timing) }

  around do |example|
    travel_to(Time.zone.local(2026, 9, 11, 12)) { example.run }
  end

  it "自分の服薬タイミングに今日のチェックを登録できる" do
    sign_in user

    expect {
      post check_path
    }.to change(MedicationCheck, :count).by(1)

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(home_path)
    expect(timing.medication_checks.pluck(:check_date))
      .to eq([ Date.current ])
  end

  it "同じ日に繰り返し登録してもチェックは重複しない" do
    sign_in user

    post check_path
    expect(response).to redirect_to(home_path)

    expect {
      post check_path
    }.not_to change(MedicationCheck, :count)

    expect(response).to redirect_to(home_path)
    expect(timing.medication_checks.where(check_date: Date.current).count)
      .to eq(1)
  end

  it "送信された日付を使わず今日の日付で登録する" do
    sign_in user

    post check_path, params: {
      medication_check: { check_date: "2026-09-01" }
    }

    expect(response).to redirect_to(home_path)
    expect(timing.medication_checks.pluck(:check_date))
      .to eq([ Date.current ])
  end

  it "今日のチェックだけ解除して過去の記録は残す" do
    yesterday_check = create(
      :medication_check, medication_timing: timing, check_date: Date.yesterday
    )
    today_check = create(
      :medication_check, medication_timing: timing, check_date: Date.current
    )
    sign_in user

    expect {
      delete check_path
    }.to change(MedicationCheck, :count).by(-1)

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(home_path)
    expect(MedicationCheck.exists?(today_check.id)).to be false
    expect(MedicationCheck.exists?(yesterday_check.id)).to be true

    expect {
      delete check_path
    }.not_to change(MedicationCheck, :count)

    expect(response).to redirect_to(home_path)
  end

  it "未ログインではチェックを登録できない" do
    expect {
      post check_path
    }.not_to change(MedicationCheck, :count)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "未ログインではチェックを解除できない" do
    check = create(
      :medication_check, medication_timing: timing, check_date: Date.current
    )

    expect {
      delete check_path
    }.not_to change(MedicationCheck, :count)

    expect(response).to redirect_to(new_user_session_path)
    expect(MedicationCheck.exists?(check.id)).to be true
  end

  it "他人の服薬タイミングにチェックを登録できない" do
    sign_in create(:user)

    expect {
      post check_path
    }.not_to change(MedicationCheck, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "他人のチェックを解除できない" do
    check = create(
      :medication_check, medication_timing: timing, check_date: Date.current
    )
    sign_in create(:user)

    expect {
      delete check_path
    }.not_to change(MedicationCheck, :count)

    expect(response).to have_http_status(:not_found)
    expect(MedicationCheck.exists?(check.id)).to be true
  end
end
