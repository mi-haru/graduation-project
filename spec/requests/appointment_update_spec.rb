require "rails_helper"

RSpec.describe "受診予定の詳細・編集", type: :request do
  let(:user) { create(:user) }
  let(:hospital) do
    create(:hospital, user: user, name: "編集前クリニック")
  end
  let!(:appointment) { create(:appointment, hospital: hospital) }

    let(:update_params) do
    {
      hospital_name: hospital.name,
      department: "眼科",
      appointment_date: "2026-10-15",
      appointment_time: "14:00"
    }
  end

  it "詳細編集画面に登録済みの内容を表示する" do
    sign_in user
    get edit_appointment_path(appointment)

    expect(response).to have_http_status(:ok)

    html = response.parsed_body

    {
      hospital_name: "編集前クリニック",
      department: "内科",
      appointment_date: "2026-10-01"
    }.each do |field, value|
      expect(html.at_css("input[name='appointment[#{field}]']")["value"])
        .to eq(value)
    end

    expect(html.at_css("input[name='appointment[appointment_time]']")["value"])
      .to match(/\A10:30(?::00(?:\.0+)?)?\z/)
    expect(html.at_css("input[type='submit']")["value"]).to eq("更新する")
  end

  it "診療科と受診日時を更新できる" do
    sign_in user

    expect {
      patch appointment_path(appointment),
            params: { appointment: update_params }
    }.not_to change { [ Hospital.count, Appointment.count ] }

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(appointments_path)

    expect(appointment.reload).to have_attributes(
      hospital_id: hospital.id,
      department: "眼科",
      appointment_date: Date.new(2026, 10, 15)
    )
    expect(appointment.appointment_time.strftime("%H:%M")).to eq("14:00")

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("[role='status']").text.strip)
      .to eq("受診予定を更新しました。")
  end

  it "医療機関名を変更しても同じ医療機関の別の予定は変わらない" do
    other_appointment = create(:appointment, hospital: hospital)
    original_attributes = other_appointment.attributes
    sign_in user

    expect {
      patch appointment_path(appointment), params: {
        appointment: update_params.merge(hospital_name: "変更後クリニック")
      }
    }.to change(Hospital, :count).by(1)
      .and change(Appointment, :count).by(0)

    expect(response).to redirect_to(appointments_path)

    appointment.reload

    expect(appointment.hospital).to have_attributes(
      name: "変更後クリニック",
      user_id: user.id
    )
    expect(appointment.hospital_id).not_to eq(hospital.id)
    expect(hospital.reload.name).to eq("編集前クリニック")
    expect(other_appointment.reload.attributes).to eq(original_attributes)
  end

  it "変更先が自分の登録済み医療機関なら再利用する" do
    existing_hospital = create(:hospital, user: user, name: "登録済みクリニック")
    sign_in user

    expect {
      patch appointment_path(appointment), params: {
        appointment: update_params.merge(hospital_name: existing_hospital.name)
      }
    }.not_to change { [ Hospital.count, Appointment.count ] }

    expect(response).to redirect_to(appointments_path)
    expect(appointment.reload.hospital_id).to eq(existing_hospital.id)
    expect(hospital.reload.name).to eq("編集前クリニック")
  end

  it "受診日が空欄なら変更を保存せず新しい医療機関も作らない" do
    sign_in user

    expect {
      patch appointment_path(appointment), params: {
        appointment: update_params.merge(
          hospital_name: "保存されないクリニック",
          appointment_date: ""
        )
      }
    }.not_to change {
      [ Hospital.count, Appointment.count, appointment.reload.attributes ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(hospital.reload.name).to eq("編集前クリニック")

    html = response.parsed_body

    expect(html.at_css("[role='alert']").text)
      .to match(/受診日.*入力してください/)

    {
      hospital_name: "保存されないクリニック",
      department: "眼科"
    }.each do |field, value|
      expect(html.at_css("input[name='appointment[#{field}]']")["value"])
        .to eq(value)
    end
  end

  it "医療機関名が空欄なら変更を保存しない" do
    sign_in user

    expect {
      patch appointment_path(appointment), params: {
        appointment: update_params.merge(hospital_name: "")
      }
    }.not_to change {
      [ Hospital.count, Appointment.count, appointment.reload.attributes ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(hospital.reload.name).to eq("編集前クリニック")

    html = response.parsed_body

    expect(html.at_css("[role='alert']").text)
      .to match(/医療機関名.*入力してください/)
    expect(html.at_css("input[name='appointment[department]']")["value"])
      .to eq("眼科")
  end

  context "他のユーザーとしてログインしている場合" do
    before { sign_in create(:user) }

    it "編集画面を開けない" do
      get edit_appointment_path(appointment)

      expect(response).to have_http_status(:not_found)
    end

    it "受診予定を更新できない" do
      expect {
        patch appointment_path(appointment), params: {
          appointment: update_params.merge(
            hospital_name: "変更できないクリニック"
          )
        }
      }.not_to change {
        [ Hospital.count, Appointment.count, appointment.reload.attributes ]
      }

      expect(response).to have_http_status(:not_found)
      expect(hospital.reload.name).to eq("編集前クリニック")
    end
  end

  context "未ログインの場合" do
    it "編集画面を開けない" do
      get edit_appointment_path(appointment)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "受診予定を更新できない" do
      expect {
        patch appointment_path(appointment), params: {
          appointment: update_params.merge(
            hospital_name: "変更できないクリニック"
          )
        }
      }.not_to change {
        [ Hospital.count, Appointment.count, appointment.reload.attributes ]
      }

      expect(response).to redirect_to(new_user_session_path)
      expect(hospital.reload.name).to eq("編集前クリニック")
    end
  end
end
