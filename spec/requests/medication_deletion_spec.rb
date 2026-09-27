require "rails_helper"

RSpec.describe "服薬情報の削除", type: :request do
  let(:user) { create(:user) }
  let(:medication) { create(:medication, user: user) }
  let(:timing) { create(:medication_timing, medication: medication) }
  let!(:check) { create(:medication_check, medication_timing: timing) }

  it "自分の薬と関連する時間帯の設定とチェックを削除する" do
    time_period = timing.time_period
    sign_in user

    expect {
      delete medication_path(medication)
    }.to change(Medication, :count).by(-1)
      .and change(MedicationTiming, :count).by(-1)
      .and change(MedicationCheck, :count).by(-1)
      .and change(TimePeriod, :count).by(0)

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(medications_path)

    expect(Medication.exists?(medication.id)).to be false
    expect(MedicationTiming.exists?(timing.id)).to be false
    expect(MedicationCheck.exists?(check.id)).to be false
    expect(TimePeriod.exists?(time_period.id)).to be true

    follow_redirect!

    expect(response.parsed_body.at_css("[role='status']").text.strip)
      .to eq("服薬情報を削除しました。")
  end

  it "未ログインでは薬と関連データを削除できない" do
    expect {
      delete medication_path(medication)
    }.not_to change {
      [ Medication.count, MedicationTiming.count, MedicationCheck.count ]
    }

    expect(response).to redirect_to(new_user_session_path)
    expect(Medication.exists?(medication.id)).to be true
    expect(MedicationTiming.exists?(timing.id)).to be true
    expect(MedicationCheck.exists?(check.id)).to be true
  end

  it "他のユーザーの薬と関連データを削除できない" do
    sign_in create(:user)

    expect {
      delete medication_path(medication)
    }.not_to change {
      [ Medication.count, MedicationTiming.count, MedicationCheck.count ]
    }

    expect(response).to have_http_status(:not_found)
    expect(Medication.exists?(medication.id)).to be true
    expect(MedicationTiming.exists?(timing.id)).to be true
    expect(MedicationCheck.exists?(check.id)).to be true
  end
end
