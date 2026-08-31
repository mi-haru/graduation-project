require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "ホームテスト",
      email: "home-test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "未ログインではログイン画面へ移動する" do
    get home_path

    assert_redirected_to new_user_session_path
  end

  test "ログイン中はホーム画面を表示できる" do
    sign_in @user

    get home_path

    assert_response :success
    assert_includes response.body, "#{@user.nickname}さん"
  end
end
