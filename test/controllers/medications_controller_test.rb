require "test_helper"

class MedicationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "服薬テスト",
      email: "medication-test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @other_user = User.create!(
      nickname: "別ユーザー",
      email: "other-medication-test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @medication = @user.medications.create!(
      name: "自分の薬",
      dosage: "1回1錠",
      start_date: Date.new(2026, 9, 1)
    )

    @other_medication = @other_user.medications.create!(
      name: "他のユーザーの薬",
      dosage: "1回2錠",
      start_date: Date.new(2026, 9, 2)
    )
  end

  test "未ログインではログイン画面へ移動する" do
    get medications_path

    assert_redirected_to new_user_session_path
  end

  test "ログインユーザーの服薬情報だけを一覧表示する" do
    sign_in @user

    get medications_path

    assert_response :success
    assert_includes response.body, @medication.name
    assert_includes response.body, @medication.dosage
    assert_not_includes response.body, @other_medication.name
  end

  test "詳細画面と編集画面への導線を表示する" do
    sign_in @user

    get medications_path

    assert_select "a[href=?]",
                  medication_path(@medication),
                  text: "詳細を見る"

    assert_select "a[href=?]",
                  edit_medication_path(@medication),
                  text: "編集する"
  end
end
