require "rails_helper"

RSpec.describe "服薬情報の詳細・編集", type: :request do
  let(:user) { create(:user) }
  let(:morning) { create(:time_period, name: "朝", position: 10) }
  let(:evening) { create(:time_period, name: "夕", position: 30) }
  let(:medication) do
    create(:medication, user: user, name: "編集前の薬")
  end
  let!(:timing) do
    create(:medication_timing, medication: medication, time_period: morning)
  end

  let(:update_params) do
    attributes_for(
      :medication,
      name: "編集後の薬",
      dosage: "2錠",
      start_date: "2026-09-02",
      end_date: "2026-09-30"
    ).merge(
      meal_timing: "before_meal",
      time_period_ids: [ evening.id.to_s ]
    )
  end

  it "未ログインでは編集画面を開けず更新もできない" do
    get edit_medication_path(medication)

    expect(response).to redirect_to(new_user_session_path)

    expect {
      patch medication_path(medication),
            params: { medication: update_params }
    }.not_to change { medication.reload.attributes }

    expect(response).to redirect_to(new_user_session_path)
  end

  it "詳細から編集画面へ移動し登録内容を表示する" do
    sign_in user

    get medication_path(medication)

    expect(response).to redirect_to(edit_medication_path(medication))

    follow_redirect!

    expect(response).to have_http_status(:ok)

    html = response.parsed_body

    {
      name: "編集前の薬",
      dosage: "1錠",
      start_date: "2026-09-01"
    }.each do |field, value|
      expect(html.at_css("input[name='medication[#{field}]']")["value"])
        .to eq(value)
    end

    expect(html.at_css("input[type='checkbox'][value='#{morning.id}'][checked]"))
      .to be_present
    expect(html.at_css("input[type='radio'][value='after_meal'][checked]"))
      .to be_present
  end

  it "服薬情報と時間帯を更新できる" do
    sign_in user

    expect {
      patch medication_path(medication),
            params: { medication: update_params }
    }.not_to change(Medication, :count)

    expect(response).to redirect_to(medications_path)

    expect(medication.reload).to have_attributes(
      name: "編集後の薬",
      dosage: "2錠",
      start_date: Date.new(2026, 9, 2),
      end_date: Date.new(2026, 9, 30),
      user_id: user.id
    )
    expect(
      medication.medication_timings.reload.pluck(:time_period_id, :meal_timing)
    ).to contain_exactly([ evening.id, "before_meal" ])

    follow_redirect!

    expect(response.parsed_body.at_css("[role='status']").text.strip)
      .to eq("服薬情報を更新しました。")
  end

  it "日付が不正なら元の薬と服薬タイミングを残す" do
    sign_in user

    expect {
      patch medication_path(medication), params: {
        medication: update_params.merge(end_date: "2026-09-01")
      }
    }.not_to change {
      [
        medication.reload.attributes,
        medication.medication_timings.reload.order(:id)
          .pluck(:id, :time_period_id, :meal_timing)
      ]
    }

    expect(response).to have_http_status(:unprocessable_content)

    html = response.parsed_body

    expect(html.at_css("[role='alert']").text).to include("服薬開始日以降")
    expect(html.at_css("input[name='medication[name]']")["value"])
      .to eq("編集後の薬")
    expect(html.at_css("input[type='checkbox'][value='#{evening.id}'][checked]"))
      .to be_present
    expect(html.at_css("input[type='radio'][value='before_meal'][checked]"))
      .to be_present
  end

  it "時間帯が未選択なら元の薬と服薬タイミングを残す" do
    sign_in user

    expect {
      patch medication_path(medication), params: {
        medication: update_params.merge(time_period_ids: [])
      }
    }.not_to change {
      [
        medication.reload.attributes,
        medication.medication_timings.reload.order(:id)
          .pluck(:id, :time_period_id, :meal_timing)
      ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.at_css("[role='alert']").text)
      .to include("服薬タイミングを1つ以上選択してください")
  end

  context "他のユーザーの薬の場合" do
    let(:other_medication) { create(:medication) }

    before { sign_in user }

    it "詳細を開けない" do
      get medication_path(other_medication)

      expect(response).to have_http_status(:not_found)
    end

    it "編集画面を開けない" do
      get edit_medication_path(other_medication)

      expect(response).to have_http_status(:not_found)
    end

    it "更新できない" do
      other_medication

      expect {
        patch medication_path(other_medication),
              params: { medication: update_params }
      }.not_to change {
        [ other_medication.reload.attributes, MedicationTiming.count ]
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  it "薬名や用量を変更しても同じ時間帯のチェック記録を保持する" do
    check = create(:medication_check, medication_timing: timing)
    original_check = check.attributes
    sign_in user

    expect {
      patch medication_path(medication), params: {
        medication: update_params.merge(
          time_period_ids: [ morning.id.to_s ],
          meal_timing: "after_meal"
        )
      }
    }.not_to change { [ MedicationTiming.count, MedicationCheck.count ] }

    expect(response).to redirect_to(medications_path)
    expect(medication.reload).to have_attributes(
      name: "編集後の薬",
      dosage: "2錠"
    )
    expect(
      medication.medication_timings.reload.pluck(:id, :time_period_id)
    ).to contain_exactly([ timing.id, morning.id ])
    expect(check.reload.attributes).to eq(original_check)
  end

  it "外した時間帯のチェックだけ削除して残る時間帯のチェックは保持する" do
    evening_timing = create(
      :medication_timing, medication: medication, time_period: evening
    )
    morning_check = create(:medication_check, medication_timing: timing)
    evening_check = create(:medication_check, medication_timing: evening_timing)
    sign_in user

    expect {
      patch medication_path(medication), params: {
        medication: update_params.merge(time_period_ids: [ morning.id.to_s ])
      }
    }.to change(MedicationTiming, :count).by(-1)
      .and change(MedicationCheck, :count).by(-1)

    expect(response).to redirect_to(medications_path)
    expect(timing.reload.meal_timing).to eq("before_meal")
    expect(MedicationCheck.exists?(morning_check.id)).to be true
    expect(MedicationTiming.exists?(evening_timing.id)).to be false
    expect(MedicationCheck.exists?(evening_check.id)).to be false
  end

  it "入力エラーでは服薬チェックも変更されない" do
    check = create(:medication_check, medication_timing: timing)
    original_check = check.attributes
    sign_in user

    expect {
      patch medication_path(medication), params: {
        medication: update_params.merge(end_date: "2026-09-01")
      }
    }.not_to change { [ MedicationTiming.count, MedicationCheck.count ] }

    expect(response).to have_http_status(:unprocessable_content)
    expect(medication.reload.name).to eq("編集前の薬")
    expect(timing.reload.meal_timing).to eq("after_meal")
    expect(check.reload.attributes).to eq(original_check)
  end
end
