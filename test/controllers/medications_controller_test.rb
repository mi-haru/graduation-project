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

  test "時間帯を表示順に並べて食事タイミングを日本語で表示する" do
    evening = TimePeriod.create!(name: "夕", position: 30)
    morning = TimePeriod.create!(name: "朝", position: 10)

    @medication.medication_timings.create!(
      time_period: evening,
      meal_timing: :after_meal
    )
    @medication.medication_timings.create!(
      time_period: morning,
      meal_timing: :after_meal
    )

    sign_in @user
    get medications_path

    assert_response :success

    assert_select "section.medisu-card" do
      assert_select "h2", text: @medication.name
      assert_select "dt", text: "飲む時間帯"
      assert_select "dd", text: "朝・夕"
      assert_select "dt", text: "食事のタイミング"
      assert_select "dd", text: "食後", count: 1

      assert_select "dt", text: /服用開始日|服用終了日|服薬開始日|服薬終了日/,
                          count: 0
    end
  end

  test "服薬タイミングが未登録なら未設定と表示する" do
    sign_in @user
    get medications_path

    assert_response :success

    assert_select "section.medisu-card" do
      assert_select "h2", text: @medication.name
      assert_select "dd", text: "未設定", count: 2
    end
  end

  test "薬が複数あっても各カードを1回だけ表示する" do
    second_medication = @user.medications.create!(
      name: "2つ目の薬",
      dosage: "1錠",
      start_date: Date.current
    )

    sign_in @user
    get medications_path

    assert_response :success

    [ @medication, second_medication ].each do |medication|
      assert_select "h2", text: medication.name, count: 1
      assert_select "a[href=?]",
                    edit_medication_path(medication),
                    count: 1
    end
  end
end
