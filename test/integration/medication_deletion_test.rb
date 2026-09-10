require "test_helper"

class MedicationDeletionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "削除テスト",
      email: "medication-deletion@example.com",
      password: "password123"
    )

    @other_user = User.create!(
      nickname: "別ユーザー",
      email: "other-deletion@example.com",
      password: "password123"
    )

    @morning = TimePeriod.create!(name: "朝", position: 10)

    @medication = @user.medications.create!(
      name: "削除テスト用の薬",
      dosage: "1錠",
      start_date: Date.new(2026, 9, 1)
    )

    @timing = @medication.medication_timings.create!(
      time_period: @morning,
      meal_timing: :after_meal
    )

    @check = @timing.medication_checks.create!(
      check_date: Date.new(2026, 9, 11)
    )
  end

  test "自分の薬と関連する時間帯の設定とチェックを削除する" do
    sign_in @user

    assert_no_difference "TimePeriod.count" do
      assert_difference(
        [ "Medication.count", "MedicationTiming.count", "MedicationCheck.count" ],
        -1
      ) do
        delete medication_path(@medication)
      end
    end

    assert_response :see_other
    assert_redirected_to medications_path
    assert_not Medication.exists?(@medication.id)
    assert_not MedicationTiming.exists?(@timing.id)
    assert_not MedicationCheck.exists?(@check.id)
    assert TimePeriod.exists?(@morning.id)

    follow_redirect!
    assert_select "[role='status']", text: "服薬情報を削除しました。"
  end

  test "未ログインでは薬と関連データを削除できない" do
    assert_no_difference(
      [ "Medication.count", "MedicationTiming.count", "MedicationCheck.count" ]
    ) do
      delete medication_path(@medication)
    end

    assert_redirected_to new_user_session_path
    assert Medication.exists?(@medication.id)
    assert MedicationTiming.exists?(@timing.id)
    assert MedicationCheck.exists?(@check.id)
  end

  test "他のユーザーの薬と関連データを削除できない" do
    sign_in @other_user

    assert_no_difference(
      [ "Medication.count", "MedicationTiming.count", "MedicationCheck.count" ]
    ) do
      assert_not_found do
        delete medication_path(@medication)
      end
    end

    assert Medication.exists?(@medication.id)
    assert MedicationTiming.exists?(@timing.id)
    assert MedicationCheck.exists?(@check.id)
  end

  private

  def assert_not_found
    yield
    assert_response :not_found
  rescue ActiveRecord::RecordNotFound
    assert true
  end
end
