require "rails_helper"

RSpec.describe "ホーム画面", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  around do |example|
    travel_to(Time.zone.local(2026, 9, 11, 12)) { example.run }
  end

  it "未ログインではログイン画面へ移動する" do
    get home_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "ログイン中はホーム画面を表示できる" do
    sign_in user
    get home_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("#{user.nickname}さん")

    html = response.parsed_body

    expect(html.at_css("nav[aria-label='メインメニュー']")).to be_present

    {
      home_path => "ホーム",
      medications_path => "服薬管理",
      appointments_path => "受診予定"
    }.each do |path, label|
      texts = html.css("a[href='#{path}']").map { |link| link.text.strip }
      expect(texts).to include(label)
    end

    expect(
      html.at_css("form[action='#{destroy_user_session_path}'] button").text.strip
    ).to eq("ログアウト")
  end

  it "今日が服薬期間に含まれる自分の薬だけを表示する" do
    morning = create(:time_period)

    [
      { name: "今日から飲む薬", start_date: Date.current },
      { name: "今日まで飲む薬", start_date: Date.yesterday, end_date: Date.current },
      { name: "明日から飲む薬", start_date: Date.tomorrow },
      { name: "昨日で終了した薬", start_date: Date.current - 7, end_date: Date.yesterday },
      { name: "別ユーザーのお薬", user: create(:user), start_date: Date.current }
    ].each do |attributes|
      medication = create(
        :medication, **{ user: user, dosage: "1回1錠" }.merge(attributes)
      )
      create(:medication_timing, medication: medication, time_period: morning)
    end

    sign_in user
    get home_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "今日から飲む薬", "今日まで飲む薬", "1回1錠", "食後"
    )
    expect(response.body).not_to include(
      "明日から飲む薬", "昨日で終了した薬", "別ユーザーのお薬"
    )
  end

  it "服薬タイミングを時間帯のposition順に表示する" do
    medication = create(:medication, user: user, start_date: Date.current)

    { "就寝前" => 40, "夕" => 30, "昼" => 20, "朝" => 10 }.each do |name, position|
      period = create(:time_period, name: name, position: position)
      create(:medication_timing, medication: medication, time_period: period)
    end

    sign_in user
    get home_path

    expect(response).to have_http_status(:ok)

    headings = response.parsed_body.css("main h3").map { |h3| h3.text.strip }

    expect(headings).to eq([ "朝", "昼", "夕", "就寝前" ])
  end

  it "今日のチェック状態に応じた操作ボタンを表示する" do
    medication = create(:medication, user: user, name: "チェック表示テストのお薬")
    morning = create(:time_period, name: "朝", position: 10)
    evening = create(:time_period, name: "夕", position: 30)

    morning_timing = create(
      :medication_timing, medication: medication, time_period: morning
    )
    evening_timing = create(
      :medication_timing, medication: medication, time_period: evening
    )

    create(:medication_check, medication_timing: morning_timing, check_date: Date.current)
    create(:medication_check, medication_timing: evening_timing, check_date: Date.yesterday)

    sign_in user
    get home_path

    expect(response).to have_http_status(:ok)

    html = response.parsed_body
    morning_form = html.at_css(
      "form[action='#{medication_timing_medication_check_path(morning_timing)}']"
    )
    evening_form = html.at_css(
      "form[action='#{medication_timing_medication_check_path(evening_timing)}']"
    )

    expect(morning_form.at_css("input[name='_method'][value='delete']")).to be_present
    expect(morning_form.at_css("button")["aria-label"])
      .to eq("#{medication.name}（朝）の服用済みを取り消す")
    expect(morning_form.at_css("span[class~='bg-[#4a654f]']")).to be_present

    expect(evening_form.at_css("input[name='_method'][value='delete']")).to be_nil
    expect(evening_form.at_css("button")["aria-label"])
      .to eq("#{medication.name}（夕）を服用済みにする")
    expect(evening_form.at_css("span[class~='bg-white']")).to be_present
  end
end
