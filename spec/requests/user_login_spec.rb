require "rails_helper"

RSpec.describe "ユーザーのログイン", type: :request do
  let!(:user) { create(:user) }

  it "正しいメールアドレスとパスワードでログインできる" do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    expect(response).to redirect_to(home_path)

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("[role='status']").text.strip)
      .to eq("ログインしました。")
  end

  it "間違ったパスワードではログインできない" do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "wrong-password"
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.at_css("[role='alert']").text.strip)
      .to eq("メールアドレスまたはパスワードが正しくありません。")
  end

  it "未登録メールアドレスでは日本語のエラーを表示する" do
    post user_session_path, params: {
      user: {
        email: "not-registered@example.com",
        password: "password123"
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.at_css("[role='alert']").text.strip)
      .to eq("メールアドレスまたはパスワードが正しくありません。")
  end
end
