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

  describe "ニックネームのバリデーション" do
    it "空欄では無効になる" do
      user = build(:user, nickname: "")

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:nickname, :blank)).to be true
    end

    it "空白だけでは無効になる" do
      user = build(:user, nickname: "   ")

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:nickname, :blank)).to be true
    end

    it "50文字なら有効になる" do
      user = build(:user, nickname: "あ" * 50)

      expect(user).to be_valid
    end

    it "51文字では無効になる" do
      user = build(:user, nickname: "あ" * 51)

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:nickname, :too_long)).to be true
    end
  end

  describe "メールアドレスのバリデーション" do
    it "空欄では無効になる" do
      user = build(:user, email: "")

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:email, :blank)).to be true
    end

    it "不正な形式では無効になる" do
      user = build(:user, email: "invalid-email")

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:email, :invalid)).to be true
    end

    it "登録済みのメールアドレスでは無効になる" do
      create(:user, email: "duplicate@example.com")
      user = build(:user, email: "duplicate@example.com")

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:email, :taken)).to be true
    end
  end

  describe "パスワードのバリデーション" do
    it "新規登録時に空欄では無効になる" do
      user = build(:user, password: "", password_confirmation: "")

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:password, :blank)).to be true
    end

    it "5文字では無効になる" do
      user = build(:user, password: "a" * 5, password_confirmation: "a" * 5)

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:password, :too_short)).to be true
    end

    it "6文字なら有効になる" do
      user = build(:user, password: "a" * 6, password_confirmation: "a" * 6)

      expect(user).to be_valid
    end

    it "128文字なら有効になる" do
      user = build(:user, password: "a" * 128, password_confirmation: "a" * 128)

      expect(user).to be_valid
    end

    it "129文字では無効になる" do
      user = build(:user, password: "a" * 129, password_confirmation: "a" * 129)

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:password, :too_long)).to be true
    end

    it "確認用パスワードが一致しなければ無効になる" do
      user = build(
        :user,
        password: "password123",
        password_confirmation: "different123"
      )

      expect(user).not_to be_valid
      expect(user.errors.of_kind?(:password_confirmation, :confirmation)).to be true
    end
  end
end
