require "rails_helper"

RSpec.describe "公開TOPページ", type: :request do
  it "未ログインでも表示できる" do
    get root_path

    expect(response).to have_http_status(:ok)
  end
end
