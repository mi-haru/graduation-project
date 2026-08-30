require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get top" do
    get root_url

    assert_response :success
    assert_select "h1", text: /服薬と通院を/
    assert_select "h1", text: /ひとつの巣に。/
    assert_select "img[alt='medi巣のロゴ']"
    assert_select "a[href=?]", new_user_registration_path, text: "新規登録"
    assert_select "button", text: "ログイン"
  end
end
