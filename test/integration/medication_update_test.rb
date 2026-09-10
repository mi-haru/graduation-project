require "test_helper"

class MedicationUpdateTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "編集テスト",
      email: "medication-update@example.com",
      password: "password123"
    )

    @other_user = User.create!(
      nickname: "別ユーザー",
      email: "other-update@example.com",
      password: "password123"
    )

    @morning = TimePeriod.create!(name: "朝", position: 10)
    @evening = TimePeriod.create!(name: "夕", position: 30)

    @medication = @user.medications.create!(
      name: "編集前の薬",
      dosage: "1錠",
      start_date: Date.new(2026, 9, 1)
    )

    @medication.medication_timings.create!(
      time_period: @morning,
      meal_timing: :after_meal
    )

    @other_medication = @other_user.medications.create!(
      name: "他のユーザーの薬",
      dosage: "1錠",
      start_date: Date.new(2026, 9, 1)
    )
  end

  test "未ログインでは編集画面を開けず更新もできない" do
    get edit_medication_path(@medication)
    assert_redirected_to new_user_session_path

    patch medication_path(@medication),
          params: { medication: update_params }

    assert_redirected_to new_user_session_path
    assert_equal "編集前の薬", @medication.reload.name
  end

  test "詳細から編集画面へ移動し登録内容を表示する" do
    sign_in @user

    get medication_path(@medication)
    assert_redirected_to edit_medication_path(@medication)

    follow_redirect!

    assert_response :success
    assert_select "input[name='medication[name]'][value='編集前の薬']"
    assert_select "input[name='medication[dosage]'][value='1錠']"
    assert_select "input[name='medication[start_date]'][value='2026-09-01']"
    assert_select "input[type='checkbox'][value='#{@morning.id}'][checked]"
    assert_select "input[type='radio'][value='after_meal'][checked]"
  end

  test "服薬情報と時間帯を更新できる" do
    sign_in @user

    assert_no_difference "Medication.count" do
      patch medication_path(@medication),
            params: { medication: update_params }
    end

    assert_redirected_to medications_path

    @medication.reload
    assert_equal "編集後の薬", @medication.name
    assert_equal "2錠", @medication.dosage
    assert_equal Date.new(2026, 9, 2), @medication.start_date
    assert_equal Date.new(2026, 9, 30), @medication.end_date
    assert_equal @user.id, @medication.user_id

    timings = @medication.medication_timings.reload
    assert_equal [ @evening.id ], timings.pluck(:time_period_id)
    assert_equal [ "before_meal" ], timings.map(&:meal_timing)

    follow_redirect!
    assert_select "[role='status']", text: "服薬情報を更新しました。"
  end

  test "日付が不正なら元の薬と服薬タイミングを残す" do
    sign_in @user

    original_attributes = @medication.attributes
    original_timings = @medication.medication_timings.order(:id)
                                  .pluck(:id, :time_period_id, :meal_timing)

    patch medication_path(@medication), params: {
      medication: update_params.merge(end_date: "2026-09-01")
    }

    assert_response :unprocessable_content
    assert_select "[role='alert']", text: /服薬開始日以降/
    assert_select "input[name='medication[name]'][value='編集後の薬']"
    assert_select "input[type='checkbox'][value='#{@evening.id}'][checked]"
    assert_select "input[type='radio'][value='before_meal'][checked]"

    assert_equal original_attributes, @medication.reload.attributes
    assert_equal original_timings,
                 @medication.medication_timings.reload.order(:id)
                            .pluck(:id, :time_period_id, :meal_timing)
  end

  test "時間帯が未選択なら元の服薬タイミングを残す" do
    sign_in @user

    original_timing_ids = @medication.medication_timings.pluck(:id)

    patch medication_path(@medication), params: {
      medication: update_params.merge(time_period_ids: [])
    }

    assert_response :unprocessable_content
    assert_select "[role='alert']",
                  text: /服薬タイミングを1つ以上選択してください/

    assert_equal "編集前の薬", @medication.reload.name
    assert_equal original_timing_ids,
                 @medication.medication_timings.reload.pluck(:id)
  end

  test "他のユーザーの薬の詳細は開けない" do
    sign_in @user

    assert_not_found do
      get medication_path(@other_medication)
    end
  end

  test "他のユーザーの薬の編集画面は開けない" do
    sign_in @user

    assert_not_found do
      get edit_medication_path(@other_medication)
    end
  end

  test "他のユーザーの薬を更新できない" do
    sign_in @user

    original_attributes = @other_medication.attributes

    assert_no_difference "MedicationTiming.count" do
      assert_not_found do
        patch medication_path(@other_medication),
              params: { medication: update_params }
      end
    end

    assert_equal original_attributes, @other_medication.reload.attributes
  end

  test "薬名や用量を変更しても同じ時間帯のチェック記録を保持する" do
    timing = @medication.medication_timings.find_by!(
      time_period: @morning
    )
    check = timing.medication_checks.create!(
      check_date: Date.new(2026, 9, 10)
    )

    sign_in @user

    assert_no_difference [ "MedicationTiming.count", "MedicationCheck.count" ] do
      patch medication_path(@medication), params: {
        medication: update_params.merge(
          time_period_ids: [ @morning.id.to_s ],
          meal_timing: "after_meal"
        )
      }
    end

    assert_redirected_to medications_path
    assert_equal "編集後の薬", @medication.reload.name
    assert_equal "2錠", @medication.dosage
    assert_equal timing.id,
                @medication.medication_timings.find_by!(
                  time_period: @morning
                ).id
    assert_equal timing.id, check.reload.medication_timing_id
    assert_equal Date.new(2026, 9, 10), check.check_date
  end

  test "外した時間帯のチェックだけ削除して残る時間帯のチェックは保持する" do
    morning_timing = @medication.medication_timings.find_by!(
      time_period: @morning
    )
    evening_timing = @medication.medication_timings.create!(
      time_period: @evening,
      meal_timing: :after_meal
    )

    morning_check = morning_timing.medication_checks.create!(
      check_date: Date.new(2026, 9, 10)
    )
    evening_check = evening_timing.medication_checks.create!(
      check_date: Date.new(2026, 9, 10)
    )

    sign_in @user

    assert_difference "MedicationTiming.count", -1 do
      assert_difference "MedicationCheck.count", -1 do
        patch medication_path(@medication), params: {
          medication: update_params.merge(
            time_period_ids: [ @morning.id.to_s ]
          )
        }
      end
    end

    assert_redirected_to medications_path
    assert MedicationTiming.exists?(morning_timing.id)
    assert MedicationCheck.exists?(morning_check.id)
    assert_equal "before_meal", morning_timing.reload.meal_timing

    assert_not MedicationTiming.exists?(evening_timing.id)
    assert_not MedicationCheck.exists?(evening_check.id)
  end

  test "入力エラーでは服薬チェックも変更されない" do
    timing = @medication.medication_timings.find_by!(
      time_period: @morning
    )
    check = timing.medication_checks.create!(
      check_date: Date.new(2026, 9, 10)
    )
    original_check_attributes = check.attributes

    sign_in @user

    assert_no_difference [ "MedicationTiming.count", "MedicationCheck.count" ] do
      patch medication_path(@medication), params: {
        medication: update_params.merge(end_date: "2026-09-01")
      }
    end

    assert_response :unprocessable_content
    assert_equal "編集前の薬", @medication.reload.name
    assert_equal "after_meal", timing.reload.meal_timing
    assert_equal original_check_attributes, check.reload.attributes
  end

  private

  def update_params
    {
      name: "編集後の薬",
      dosage: "2錠",
      start_date: "2026-09-02",
      end_date: "2026-09-30",
      meal_timing: "before_meal",
      time_period_ids: [ @evening.id.to_s ]
    }
  end

  def assert_not_found
    yield
    assert_response :not_found
  rescue ActiveRecord::RecordNotFound
    assert true
  end
end
