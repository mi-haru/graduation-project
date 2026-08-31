require "test_helper"

class RememberMeTest < ActionDispatch::IntegrationTest
  test "remember me is not available" do
    assert_not_includes User.devise_modules, :rememberable

    get new_user_session_path

    assert_response :success
    assert_select "input[name='user[remember_me]']", count: 0
  end
end
