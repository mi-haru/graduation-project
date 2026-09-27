require "rails_helper"

RSpec.describe "受診予定の削除", type: :request do
  let(:user) { create(:user) }
  let(:hospital) { create(:hospital, user: user) }
  let!(:appointment) { create(:appointment, hospital: hospital) }
  let!(:other_appointment) { create(:appointment, hospital: hospital) }

  it "自分の予定だけを削除して一覧へ戻る" do
    remaining_attributes = other_appointment.attributes
    sign_in user

    expect {
      delete appointment_path(appointment)
    }.to change(Appointment, :count).by(-1)
      .and change(Hospital, :count).by(0)

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(appointments_path)
    expect(Appointment.exists?(appointment.id)).to be false
    expect(Hospital.exists?(hospital.id)).to be true
    expect(other_appointment.reload.attributes).to eq(remaining_attributes)

    follow_redirect!

    expect(response).to have_http_status(:ok)

    html = response.parsed_body

    expect(html.at_css("[role='status']").text.strip)
      .to eq("受診予定を削除しました。")
    expect(html.css("a[href='#{edit_appointment_path(appointment)}']"))
      .to be_empty

    links = html.css("a[href='#{edit_appointment_path(other_appointment)}']")

    expect(links.size).to eq(1)
    expect(links.first.text.strip).to eq("詳細・編集")
  end

  it "未ログインでは受診予定を削除できない" do
    expect {
      delete appointment_path(appointment)
    }.not_to change { [ Hospital.count, Appointment.count ] }

    expect(response).to redirect_to(new_user_session_path)
    expect(Appointment.exists?(appointment.id)).to be true
    expect(Appointment.exists?(other_appointment.id)).to be true
    expect(Hospital.exists?(hospital.id)).to be true
  end

  it "他のユーザーの受診予定は削除できない" do
    sign_in create(:user)

    expect {
      delete appointment_path(appointment)
    }.not_to change { [ Hospital.count, Appointment.count ] }

    expect(response).to have_http_status(:not_found)
    expect(Appointment.exists?(appointment.id)).to be true
    expect(Appointment.exists?(other_appointment.id)).to be true
    expect(Hospital.exists?(hospital.id)).to be true
  end
end
