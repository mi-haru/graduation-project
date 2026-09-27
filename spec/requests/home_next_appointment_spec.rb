require "rails_helper"

RSpec.describe "ホーム画面の次回受診予定", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:hour) { 12 }

  around do |example|
    travel_to(Time.zone.local(2026, 10, 1, hour)) { example.run }
  end

  before { sign_in user }

  it "自分の受診予定の中から最も近い1件だけを表示する" do
    [
      [ user, "次回表示クリニック", Date.current, "14:00" ],
      [ user, "翌日のクリニック", Date.tomorrow, "09:00" ],
      [ create(:user), "別ユーザーのクリニック", Date.current, "13:00" ]
    ].each do |owner, name, date, time|
      hospital = create(:hospital, user: owner, name: name)
      create(
        :appointment,
        hospital: hospital,
        appointment_date: date,
        appointment_time: time
      )
    end

    get home_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "次回表示クリニック", "内科", "2026年10月1日", "14:00"
    )
    expect(response.body).not_to include(
      "翌日のクリニック", "別ユーザーのクリニック"
    )

    links = response.parsed_body.css("a[href='#{new_appointment_path}']")

    expect(links.size).to eq(1)
    expect(links.first.text.strip).to eq("受診予定を登録する")
  end

  it "過去の予定を除外して今日の未経過の予定を表示する" do
    [
      [ "昨日のクリニック", Date.yesterday, "15:00" ],
      [ "今朝のクリニック", Date.current, "10:00" ],
      [ "今日午後のクリニック", Date.current, "14:00" ]
    ].each do |name, date, time|
      hospital = create(:hospital, user: user, name: name)
      create(
        :appointment,
        hospital: hospital,
        appointment_date: date,
        appointment_time: time
      )
    end

    get home_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("今日午後のクリニック", "14:00")
    expect(response.body).not_to include("昨日のクリニック", "今朝のクリニック")
  end

  it "同じ日なら時間未設定より時間指定ありの予定を優先する" do
    [
      [ "時間未設定クリニック", nil ],
      [ "午後のクリニック", "14:00" ]
    ].each do |name, time|
      hospital = create(:hospital, user: user, name: name)
      create(
        :appointment,
        hospital: hospital,
        appointment_date: Date.current,
        appointment_time: time
      )
    end

    get home_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("午後のクリニック", "14:00")
    expect(response.body).not_to include("時間未設定クリニック")
  end

  context "現在時刻が23時の場合" do
    let(:hour) { 23 }

    it "今日の時間未設定の予定を明日の予定より優先する" do
      [
        [ "今日の時間未設定クリニック", Date.current, nil ],
        [ "明日のクリニック", Date.tomorrow, "09:00" ]
      ].each do |name, date, time|
        hospital = create(:hospital, user: user, name: name)
        create(
          :appointment,
          hospital: hospital,
          appointment_date: date,
          appointment_time: time
        )
      end

      get home_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("今日の時間未設定クリニック", "時間未設定")
      expect(response.body).not_to include("明日のクリニック")
    end
  end

  it "過去の予定しかなければ次回の予定がない案内を表示する" do
    hospital = create(:hospital, user: user, name: "過去のクリニック")

    [ [ Date.yesterday, nil ], [ Date.current, "10:00" ] ].each do |date, time|
      create(
        :appointment,
        hospital: hospital,
        appointment_date: date,
        appointment_time: time
      )
    end

    get home_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("次回の受診予定はありません")
    expect(response.body).not_to include("過去のクリニック")

    links = response.parsed_body.css("a[href='#{new_appointment_path}']")

    expect(links.size).to eq(1)
    expect(links.first.text.strip).to eq("受診予定を登録する")
  end

  it "自分に予定がなければ他のユーザーの予定を表示しない" do
    other_hospital = create(:hospital, name: "他人の未来クリニック")
    create(
      :appointment,
      hospital: other_hospital,
      appointment_date: Date.tomorrow,
      appointment_time: "09:00"
    )

    get home_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("次回の受診予定はありません")
    expect(response.body).not_to include("他人の未来クリニック")
  end

  context "現在時刻が朝6時の場合" do
    let(:hour) { 6 }

    it "日本時間で朝の予定を午後の予定より先に表示する" do
      [ [ "午後のクリニック", "14:00" ], [ "朝のクリニック", "08:00" ] ].each do |name, time|
        hospital = create(:hospital, user: user, name: name)
        create(
          :appointment,
          hospital: hospital,
          appointment_date: Date.current,
          appointment_time: time
        )
      end

      get home_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("朝のクリニック", "08:00")
      expect(response.body).not_to include("午後のクリニック")
    end
  end
end
