require "test_helper"

class MedicationChecksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "チェックテスト",
      email: "check-test@example.com",
      password: "password123"
    )

    @other_user = User.create!(
      nickname: "別ユーザー",
      email: "other-check-test@example.com",
      password: "password123"
    )

    @morning = TimePeriod.create!(name: "朝", position: 10)

    medication = @user.medications.create!(
      name: "チェック用の薬",
      dosage: "1錠",
      start_date: Date.new(2026, 9, 1)
    )

    @timing = medication.medication_timings.create!(
      time_period: @morning,
      meal_timing: :after_meal
    )

    @check_path = medication_timing_medication_check_path(@timing)

    travel_to Time.zone.local(2026, 9, 11, 12)
  end

  teardown do
    travel_back
  end

  test "自分の服薬タイミングに今日のチェックを登録できる" do
    sign_in @user

    assert_difference "MedicationCheck.count", 1 do
      post @check_path
    end

    assert_response :see_other
    assert_redirected_to home_path
    assert @timing.medication_checks.exists?(check_date: Date.current)
  end

  test "同じ日に繰り返し登録してもチェックは重複しない" do
    sign_in @user

    post @check_path
    assert_redirected_to home_path

    assert_no_difference "MedicationCheck.count" do
      post @check_path
    end

    assert_redirected_to home_path
    assert_equal 1,
                 @timing.medication_checks.where(check_date: Date.current).count
  end

  test "送信された日付を使わず今日の日付で登録する" do
    sign_in @user

    post @check_path, params: {
      medication_check: { check_date: "2026-09-01" }
    }

    assert_redirected_to home_path
    assert_equal [ Date.current ],
                 @timing.medication_checks.pluck(:check_date)
  end

  test "今日のチェックだけ解除して過去の記録は残す" do
    sign_in @user

    yesterday_check = @timing.medication_checks.create!(
      check_date: Date.yesterday
    )
    today_check = @timing.medication_checks.create!(
      check_date: Date.current
    )

    assert_difference "MedicationCheck.count", -1 do
      delete @check_path
    end

    assert_response :see_other
    assert_redirected_to home_path
    assert_not MedicationCheck.exists?(today_check.id)
    assert MedicationCheck.exists?(yesterday_check.id)

    assert_no_difference "MedicationCheck.count" do
      delete @check_path
    end

    assert_redirected_to home_path
  end

  test "未ログインではチェックを登録できない" do
    assert_no_difference "MedicationCheck.count" do
      post @check_path
    end

    assert_redirected_to new_user_session_path
  end

  test "未ログインではチェックを解除できない" do
    check = @timing.medication_checks.create!(check_date: Date.current)

    assert_no_difference "MedicationCheck.count" do
      delete @check_path
    end

    assert_redirected_to new_user_session_path
    assert MedicationCheck.exists?(check.id)
  end

  test "他人の服薬タイミングにチェックを登録できない" do
    sign_in @other_user

    assert_no_difference "MedicationCheck.count" do
      assert_not_found do
        post @check_path
      end
    end
  end

  test "他人のチェックを解除できない" do
    check = @timing.medication_checks.create!(check_date: Date.current)
    sign_in @other_user

    assert_no_difference "MedicationCheck.count" do
      assert_not_found do
        delete @check_path
      end
    end

    assert MedicationCheck.exists?(check.id)
  end

  private

  def assert_not_found
    yield
    assert_response :not_found
  rescue ActiveRecord::RecordNotFound
    assert true
  end
end
