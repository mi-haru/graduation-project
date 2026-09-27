require "rails_helper"

RSpec.describe "受診予定の一覧表示", type: :request do
  let(:user) { create(:user) }
  let(:hospital) do
    create(:hospital, user: user, name: "自分のクリニック")
  end
  let!(:appointment) { create(:appointment, hospital: hospital) }
  let!(:other_appointment) do
    create(
      :appointment,
      hospital: create(:hospital, name: "別ユーザーのクリニック"),
      department: "皮膚科"
    )
  end

  it "未ログインではログイン画面へ移動する" do
    get appointments_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "自分の受診予定だけを表示する" do
    sign_in user
    get appointments_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "自分のクリニック", "内科", "2026年10月1日", "10:30"
    )
    expect(response.body).not_to include(
      "別ユーザーのクリニック", "皮膚科"
    )
  end

  it "診療科と時間が未登録でも表示できる" do
    appointment.update!(department: nil, appointment_time: nil)

    sign_in user
    get appointments_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("自分のクリニック", "時間未設定")
    expect(response.body).not_to include("内科")
  end

  it "受診予定が複数あっても各カードを1回だけ表示する" do
    second_hospital = create(:hospital, user: user, name: "2つ目のクリニック")
    create(:appointment, hospital: second_hospital)

    sign_in user
    get appointments_path

    expect(response).to have_http_status(:ok)

    names = response.parsed_body.css("section.medisu-card h2")
      .map { |h2| h2.text.strip }

    expect(names).to contain_exactly("自分のクリニック", "2つ目のクリニック")
  end

  it "自分の受診予定がなければ未登録の案内を表示する" do
    appointment.destroy!

    sign_in user
    get appointments_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("受診予定はまだありません")
    expect(response.body).not_to include("別ユーザーのクリニック")
  end

  it "一覧に各受診予定の詳細編集リンクを表示する" do
    second_appointment = create(:appointment, hospital: hospital)

    sign_in user
    get appointments_path

    expect(response).to have_http_status(:ok)

    [ appointment, second_appointment ].each do |record|
      links = response.parsed_body.css(
        "a[href='#{edit_appointment_path(record)}']"
      )

      expect(links.size).to eq(1)
      expect(links.first.text.strip).to eq("詳細・編集")
    end
  end
end
