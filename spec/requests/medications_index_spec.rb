require "rails_helper"

RSpec.describe "服薬情報の一覧表示", type: :request do
  let(:user) { create(:user) }

  it "未ログインではログイン画面へ移動する" do
    get medications_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "ログインユーザーの服薬情報だけを一覧表示する" do
    medication = create(
      :medication,
      user: user,
      name: "自分の薬",
      dosage: "1回1錠"
    )
    other_medication = create(
      :medication,
      name: "他のユーザーの薬"
    )

    sign_in user
    get medications_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(medication.name)
    expect(response.body).to include(medication.dosage)
    expect(response.body).not_to include(other_medication.name)
  end

  it "詳細編集画面へのリンクを1つ表示する" do
    medication = create(:medication, user: user)

    sign_in user
    get medications_path

    expect(response).to have_http_status(:ok)

    html = response.parsed_body
    edit_links = html.css(
      "a[href='#{edit_medication_path(medication)}']"
    )

    expect(edit_links.size).to eq(1)
    expect(edit_links.first.text.strip).to eq("詳細・編集")

    expect(
      html.css("a[href='#{medication_path(medication)}']")
    ).to be_empty
  end

  it "時間帯を表示順に並べて食事タイミングを日本語で表示する" do
    medication = create(:medication, user: user)
    evening = create(:time_period, name: "夕", position: 30)
    morning = create(:time_period, name: "朝", position: 10)

    create(
      :medication_timing,
      medication: medication,
      time_period: evening,
      meal_timing: :after_meal
    )
    create(
      :medication_timing,
      medication: medication,
      time_period: morning,
      meal_timing: :after_meal
    )

    sign_in user
    get medications_path

    expect(response).to have_http_status(:ok)

    card = response.parsed_body.css("section.medisu-card").find do |section|
      section.at_css("h2")&.text&.strip == medication.name
    end

    expect(card).to be_present

    labels = card.css("dt").map { |element| element.text.strip }
    values = card.css("dd").map { |element| element.text.strip }

    expect(labels).to include("飲む時間帯", "食事のタイミング")
    expect(values).to include("朝・夕")
    expect(values.count("食後")).to eq(1)

    expect(
      labels.grep(/服用開始日|服用終了日|服薬開始日|服薬終了日/)
    ).to be_empty
  end

  it "服薬タイミングが未登録なら未設定と表示する" do
    create(:medication, user: user)

    sign_in user
    get medications_path

    expect(response).to have_http_status(:ok)

    values = response.parsed_body.css("section.medisu-card dd")
      .map { |element| element.text.strip }

    expect(values.count("未設定")).to eq(2)
  end

  it "薬が複数あっても各カードを1回だけ表示する" do
    medications = [
      create(:medication, user: user, name: "1つ目の薬"),
      create(:medication, user: user, name: "2つ目の薬")
    ]

    sign_in user
    get medications_path

    expect(response).to have_http_status(:ok)

    html = response.parsed_body
    names = html.css("section.medisu-card h2").map { |h2| h2.text.strip }

    expect(names).to contain_exactly(*medications.map(&:name))

    medications.each do |medication|
      expect(
        html.css("a[href='#{edit_medication_path(medication)}']").size
      ).to eq(1)
    end
  end
end
