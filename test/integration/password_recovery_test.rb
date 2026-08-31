require "test_helper"

class PasswordRecoveryTest < ActionDispatch::IntegrationTest
  test "password recovery route is not available" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path(
        "/users/password/new",
        method: :get
      )
    end
  end
end
