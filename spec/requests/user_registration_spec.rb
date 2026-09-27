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
end
