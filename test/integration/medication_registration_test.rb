require "test_helper"

class MedicationRegistrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "服薬登録テスト",
      email: "medication-registration@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @morning = TimePeriod.create!(name: "朝", position: 10)
    @evening = TimePeriod.create!(name: "夕", position: 30)
  end

  test "未ログインでは服薬情報を登録できない" do
    assert_no_difference [ "Medication.count", "MedicationTiming.count" ] do
      post medications_path, params: { medication: valid_params }
    end

    assert_redirected_to new_user_session_path
  end

  test "自分の薬として複数の服薬タイミングを登録できる" do
    sign_in @user

    assert_difference "Medication.count", 1 do
      assert_difference "MedicationTiming.count", 2 do
        post medications_path, params: { medication: valid_params }
      end
    end

    assert_redirected_to medications_path

    medication = @user.medications.find_by!(name: "登録テスト用の薬")

    assert_equal "1錠", medication.dosage
    assert_equal Date.new(2026, 9, 6), medication.start_date
    assert_nil medication.end_date
    assert_equal [ @morning.id, @evening.id ].sort,
                 medication.medication_timings.pluck(:time_period_id).sort
    assert medication.medication_timings.all?(&:after_meal?)

    follow_redirect!
    assert_select "[role='status']", text: "服薬情報を登録しました。"
  end

  test "終了日が開始日より前なら薬も服薬タイミングも保存しない" do
    sign_in @user

    assert_no_difference [ "Medication.count", "MedicationTiming.count" ] do
      post medications_path, params: {
        medication: valid_params.merge(end_date: "2026-09-05")
      }
    end

    assert_response :unprocessable_content
    assert_select "[role='alert']", text: /服薬開始日以降/
    assert_select "input[name='medication[name]'][value='登録テスト用の薬']"
    assert_select "input[type='checkbox'][value='#{@morning.id}'][checked]"
    assert_select "input[type='radio'][value='after_meal'][checked]"
  end

  test "服薬タイミングが未選択なら保存しない" do
    sign_in @user

    assert_no_difference [ "Medication.count", "MedicationTiming.count" ] do
      post medications_path, params: {
        medication: valid_params.merge(time_period_ids: [])
      }
    end

    assert_response :unprocessable_content
    assert_select "[role='alert']",
                  text: /服薬タイミングを1つ以上選択してください/
  end

  private

  def valid_params
    {
      name: "登録テスト用の薬",
      dosage: "1錠",
      start_date: "2026-09-06",
      end_date: "",
      meal_timing: "after_meal",
      time_period_ids: [ @morning.id.to_s, @evening.id.to_s ]
    }
  end
end
