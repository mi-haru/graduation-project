require "rails_helper"

RSpec.describe "公開TOPページ", type: :request do
  it "未ログインでも見出し・ロゴ・登録とログインのリンクを表示する" do
    get root_path

    expect(response).to have_http_status(:ok)

    html = response.parsed_body
    headings = html.css("h1").text

    expect(headings).to include("服薬と通院を", "ひとつの巣に。")
    expect(html.at_css("img[alt='medi巣のロゴ']")).to be_present

    {
      new_user_registration_path => "新規登録",
      new_user_session_path => "ログイン"
    }.each do |path, label|
      texts = html.css("a[href='#{path}']").map { |link| link.text.strip }
      expect(texts).to include(label)
    end
  end
end
