require "test_helper"

class UserLoginTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      nickname: "ログインテスト",
      email: "login-test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "正しいメールアドレスとパスワードでログインできる" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }

    assert_redirected_to home_path

    follow_redirect!

    assert_response :success
    assert_select "[role='status']", text: "ログインしました。"
  end

  test "間違ったパスワードではログインできない" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "wrong-password"
      }
    }

    assert_response :unprocessable_content
    assert_select "[role='alert']",
                  text: "メールアドレスまたはパスワードが正しくありません。"
  end

  test "未登録メールアドレスでは日本語のエラーを表示する" do
    post user_session_path, params: {
      user: {
        email: "not-registered@example.com",
        password: "password123"
      }
    }

    assert_response :unprocessable_content
    assert_select "[role='alert']",
                  text: "メールアドレスまたはパスワードが正しくありません。"
end
end
