require "rails_helper"

RSpec.describe User, type: :model do
  it "FactoryBotで有効なユーザーを保存できる" do
    user = create(:user)

    expect(user).to be_persisted
    expect(user).to be_valid
  end

  it "複数のユーザーを異なるメールアドレスで作成できる" do
    first_user = create(:user)
    second_user = create(:user)

    expect(first_user.email).not_to eq(second_user.email)
  end
end
