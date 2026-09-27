require "rails_helper"

RSpec.describe "受診予定の登録", type: :request do
  let(:user) { create(:user) }
  let(:valid_params) do
    attributes_for(:appointment).merge(
      hospital_name: "登録テストクリニック"
    )
  end

  it "新しい医療機関と受診予定を登録できる" do
    sign_in user

    expect {
      post appointments_path, params: { appointment: valid_params }
    }.to change(Hospital, :count).by(1)
      .and change(Appointment, :count).by(1)

    expect(response).to redirect_to(appointments_path)

    hospital = user.hospitals.find_by!(name: valid_params[:hospital_name])
    appointment = hospital.appointments.sole

    expect(appointment).to have_attributes(
      department: "内科",
      appointment_date: Date.new(2026, 10, 1)
    )
    expect(appointment.appointment_time.strftime("%H:%M")).to eq("10:30")

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("[role='status']").text.strip)
      .to eq("受診予定を登録しました。")
  end

  it "同名の自分の医療機関を再利用し診療科と時間は空欄で登録できる" do
    hospital = create(:hospital, user: user, name: "再利用クリニック")
    sign_in user

    expect {
      post appointments_path, params: {
        appointment: valid_params.merge(
          hospital_name: hospital.name,
          department: "",
          appointment_date: "2026-10-02",
          appointment_time: ""
        )
      }
    }.to change(Appointment, :count).by(1)
      .and change(Hospital, :count).by(0)

    expect(response).to redirect_to(appointments_path)

    appointment = hospital.appointments.sole

    expect(appointment.department).to be_blank
    expect(appointment.appointment_time).to be_nil
    expect(appointment.appointment_date).to eq(Date.new(2026, 10, 2))
  end

  it "医療機関名が空欄なら保存できない" do
    sign_in user

    expect {
      post appointments_path, params: {
        appointment: valid_params.merge(hospital_name: "")
      }
    }.not_to change { [ Hospital.count, Appointment.count ] }

    expect(response).to have_http_status(:unprocessable_content)

    html = response.parsed_body

    expect(html.at_css("[role='alert']").text)
      .to match(/医療機関名.*入力してください/)

    { department: "内科", appointment_date: "2026-10-01" }.each do |field, value|
      expect(html.at_css("input[name='appointment[#{field}]']")["value"])
        .to eq(value)
    end
  end

  it "受診日が空欄なら新しい医療機関も保存されない" do
    sign_in user

    expect {
      post appointments_path, params: {
        appointment: valid_params.merge(
          hospital_name: "保存されないクリニック",
          department: "眼科",
          appointment_date: ""
        )
      }
    }.not_to change { [ Hospital.count, Appointment.count ] }

    expect(response).to have_http_status(:unprocessable_content)

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

  it "他のユーザーの同名医療機関は再利用しない" do
    other_hospital = create(:hospital, name: valid_params[:hospital_name])
    sign_in user

    expect {
      post appointments_path, params: { appointment: valid_params }
    }.to change(Hospital, :count).by(1)
      .and change(Appointment, :count).by(1)

    expect(response).to redirect_to(appointments_path)

    my_hospital = user.hospitals.find_by!(name: other_hospital.name)

    expect(my_hospital.id).not_to eq(other_hospital.id)
    expect(my_hospital.appointments.count).to eq(1)
    expect(other_hospital.appointments.count).to eq(0)
  end

  it "未ログインでは登録画面を開けない" do
    get new_appointment_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "未ログインでは医療機関と受診予定を登録できない" do
    expect {
      post appointments_path, params: { appointment: valid_params }
    }.not_to change { [ Hospital.count, Appointment.count ] }

    expect(response).to redirect_to(new_user_session_path)
  end
end
