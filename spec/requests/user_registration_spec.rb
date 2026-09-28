require "rails_helper"

RSpec.describe "ユーザーの新規登録", type: :request do
  it "正しい情報で登録するとユーザーが作成されホーム画面へ移動する" do
    user_attributes = attributes_for(:user, nickname: "新規登録テスト")

    expect {
      post user_registration_path, params: {
        user: user_attributes
      }
    }.to change(User, :count).by(1)

    registered_user = User.find_by!(email: user_attributes[:email])

    expect(registered_user.nickname).to eq("新規登録テスト")
    expect(response).to redirect_to(home_path)
  end

  it "新規登録画面のラベルと案内を日本語で表示する" do
    get new_user_registration_path

    expect(response).to have_http_status(:ok)

    html = response.parsed_body
    labels = html.css("label").map { |label| label.text.strip }

    expect(labels).to include(
      "ユーザー名", "メールアドレス", "パスワード", "パスワード（確認）"
    )
    expect(html.at_css("h1").text.strip).to eq("新規登録")
    expect(html.at_css("input[type='submit']")["value"]).to eq("登録する")
    expect(html.text).to include(
      "medi巣をはじめましょう",
      "#{User.password_length.min}文字以上で入力してください",
      "すでにアカウントをお持ちですか？"
    )
  end

  it "入力エラーを日本語で表示する" do
    attributes = attributes_for(
      :user,
      email: "",
      password: "a",
      password_confirmation: "a"
    )

    expect {
      post user_registration_path, params: { user: attributes }
    }.not_to change(User, :count)

    expect(response).to have_http_status(:unprocessable_content)

    alert = response.parsed_body.at_css("#error_explanation[role='alert']")

    expect(alert).to be_present
    expect(alert.at_css("h2").text).to include("ユーザーを保存できませんでした")
    expect(alert.text).to match(/メールアドレス\s*を入力してください/)
    expect(alert.text).to include(
      "は#{User.password_length.min}文字以上で入力してください"
    )
    expect(alert.text).not_to match(/translation missing/i)
    expect(alert["class"].split).to include("text-red-700")
  end
end
