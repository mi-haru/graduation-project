require "rails_helper"

RSpec.describe "ユーザーのログアウト", type: :request do
  it "ログアウト後はログイン画面へ移動しホーム画面を閲覧できない" do
    user = create(:user)
    sign_in user

    delete destroy_user_session_path

    expect(response).to redirect_to(new_user_session_path)

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("[role='status']").text.strip)
      .to eq("ログアウトしました。")

    get home_path

    expect(response).to redirect_to(new_user_session_path)
  end
end
