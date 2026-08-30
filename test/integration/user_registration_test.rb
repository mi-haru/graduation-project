require "test_helper"

class UserRegistrationTest < ActionDispatch::IntegrationTest
  test "user can sign up with valid information" do
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          nickname: "テストユーザー",
          email: "new-user@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_equal "テストユーザー", User.last.nickname
    assert_redirected_to root_path
  end
end
