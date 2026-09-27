require "rails_helper"

RSpec.describe "服薬情報の登録", type: :request do
  let(:user) { create(:user) }
  let(:morning) { create(:time_period, name: "朝", position: 10) }
  let(:evening) { create(:time_period, name: "夕", position: 30) }

  let(:valid_params) do
    attributes_for(
      :medication,
      name: "登録テスト用の薬",
      start_date: "2026-09-06",
      end_date: ""
    ).merge(
      meal_timing: "after_meal",
      time_period_ids: [ morning.id.to_s, evening.id.to_s ]
    )
  end

  it "未ログインでは服薬情報を登録できない" do
    expect {
      post medications_path, params: { medication: valid_params }
    }.not_to change { [ Medication.count, MedicationTiming.count ] }

    expect(response).to redirect_to(new_user_session_path)
  end

  it "自分の薬として複数の服薬タイミングを登録できる" do
    sign_in user

    expect {
      post medications_path, params: { medication: valid_params }
    }.to change(Medication, :count).by(1)
      .and change(MedicationTiming, :count).by(2)

    expect(response).to redirect_to(medications_path)

    medication = user.medications.find_by!(name: valid_params[:name])

    expect(medication.dosage).to eq("1錠")
    expect(medication.start_date).to eq(Date.new(2026, 9, 6))
    expect(medication.end_date).to be_nil
    expect(
      medication.medication_timings.pluck(:time_period_id, :meal_timing)
    ).to contain_exactly(
      [ morning.id, "after_meal" ],
      [ evening.id, "after_meal" ]
    )

    follow_redirect!

    expect(response.parsed_body.at_css("[role='status']").text.strip)
      .to eq("服薬情報を登録しました。")
  end

  it "終了日が開始日より前なら保存せず入力内容を保持する" do
    sign_in user

    expect {
      post medications_path, params: {
        medication: valid_params.merge(end_date: "2026-09-05")
      }
    }.not_to change { [ Medication.count, MedicationTiming.count ] }

    expect(response).to have_http_status(:unprocessable_content)

    html = response.parsed_body

    expect(html.at_css("[role='alert']").text).to include("服薬開始日以降")
    expect(html.at_css("input[name='medication[name]']")["value"])
      .to eq(valid_params[:name])
    expect(html.at_css("input[type='checkbox'][value='#{morning.id}'][checked]"))
      .to be_present
    expect(html.at_css("input[type='radio'][value='after_meal'][checked]"))
      .to be_present
  end

  it "服薬タイミングが未選択なら保存しない" do
    sign_in user

    expect {
      post medications_path, params: {
        medication: valid_params.merge(time_period_ids: [])
      }
    }.not_to change { [ Medication.count, MedicationTiming.count ] }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.at_css("[role='alert']").text)
      .to include("服薬タイミングを1つ以上選択してください")
  end
end
