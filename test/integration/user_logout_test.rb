require "test_helper"

class UserLogoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "ログアウトテスト",
      email: "logout-test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "ログアウト後はログイン画面へ移動しホーム画面を閲覧できない" do
    sign_in @user

    delete destroy_user_session_path

    assert_redirected_to new_user_session_path

    follow_redirect!

    assert_response :success
    assert_select "[role='status']", text: "ログアウトしました。"

    get home_path

    assert_redirected_to new_user_session_path
  end
end
