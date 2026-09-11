require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "ホームテスト",
      email: "home-test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "未ログインではログイン画面へ移動する" do
    get home_path

    assert_redirected_to new_user_session_path
  end

  test "ログイン中はホーム画面を表示できる" do
    sign_in @user

    get home_path

    assert_response :success
    assert_includes response.body, "#{@user.nickname}さん"
    assert_select "nav[aria-label='メインメニュー']"
    assert_select "a[href=?]", home_path, text: "ホーム"
    assert_select "a[href=?]", medications_path, text: "服薬管理"
    assert_select "button[disabled]", text: /受診予定/
    assert_select "form[action=?]", destroy_user_session_path do
      assert_select "button", text: "ログアウト"
    end
  end

  test "今日が服薬期間に含まれる自分の薬だけを表示する" do
    travel_to Time.zone.local(2026, 9, 11, 12, 0, 0) do
      morning = TimePeriod.create!(name: "朝", position: 10)

      other_user = User.create!(
        nickname: "別ユーザー",
        email: "other-home-test@example.com",
        password: "password123"
      )

      medications = [
        {
          user: @user,
          name: "今日から飲む薬",
          start_date: Date.current,
          end_date: nil
        },
        {
          user: @user,
          name: "今日まで飲む薬",
          start_date: Date.yesterday,
          end_date: Date.current
        },
        {
          user: @user,
          name: "明日から飲む薬",
          start_date: Date.tomorrow,
          end_date: nil
        },
        {
          user: @user,
          name: "昨日で終了した薬",
          start_date: Date.current - 7,
          end_date: Date.yesterday
        },
        {
          user: other_user,
          name: "別ユーザーのお薬",
          start_date: Date.current,
          end_date: nil
        }
      ]

      medications.each do |attributes|
        medication = Medication.create!(
          attributes.merge(dosage: "1回1錠")
        )

        medication.medication_timings.create!(
          time_period: morning,
          meal_timing: :after_meal
        )
      end

      sign_in @user
      get home_path

      assert_response :success

      assert_includes response.body, "今日から飲む薬"
      assert_includes response.body, "今日まで飲む薬"
      assert_includes response.body, "1回1錠"
      assert_includes response.body, "食後"

      assert_not_includes response.body, "明日から飲む薬"
      assert_not_includes response.body, "昨日で終了した薬"
      assert_not_includes response.body, "別ユーザーのお薬"
    end
  end

  test "服薬タイミングを時間帯のposition順に表示する" do
    travel_to Time.zone.local(2026, 9, 11, 12, 0, 0) do
      medication = @user.medications.create!(
        name: "表示順テストのお薬",
        dosage: "1錠",
        start_date: Date.current
      )

      [
        [ "就寝前", 40 ],
        [ "夕", 30 ],
        [ "昼", 20 ],
        [ "朝", 10 ]
      ].each do |name, position|
        period = TimePeriod.create!(
          name: name,
          position: position
        )

        medication.medication_timings.create!(
          time_period: period,
          meal_timing: :after_meal
        )
      end

      sign_in @user
      get home_path

      assert_response :success

      headings = css_select("main h3").map { |heading| heading.text.strip }

      assert_equal [ "朝", "昼", "夕", "就寝前" ], headings
    end
  end

  test "今日のチェック状態に応じた操作ボタンを表示する" do
    travel_to Time.zone.local(2026, 9, 11, 12, 0, 0) do
      medication = @user.medications.create!(
        name: "チェック表示テストのお薬",
        dosage: "1錠",
        start_date: Date.yesterday
      )

      morning = TimePeriod.create!(name: "朝", position: 10)
      evening = TimePeriod.create!(name: "夕", position: 30)

      morning_timing = medication.medication_timings.create!(
        time_period: morning,
        meal_timing: :after_meal
      )

      evening_timing = medication.medication_timings.create!(
        time_period: evening,
        meal_timing: :after_meal
      )

      morning_timing.medication_checks.create!(
        check_date: Date.current
      )

      evening_timing.medication_checks.create!(
        check_date: Date.yesterday
      )

      sign_in @user
      get home_path

      assert_response :success

      assert_select "form[action=?]",
                    medication_timing_medication_check_path(morning_timing) do
        assert_select "input[name='_method'][value='delete']"
        assert_select "button[aria-label=?]",
                      "チェック表示テストのお薬（朝）の服用済みを取り消す"
        assert_select "span[class~='bg-[#4a654f]']"
      end

      assert_select "form[action=?]",
                    medication_timing_medication_check_path(evening_timing) do
        assert_select "input[name='_method'][value='delete']", count: 0
        assert_select "button[aria-label=?]",
                      "チェック表示テストのお薬（夕）を服用済みにする"
        assert_select "span[class~='bg-white']"
      end
    end
  end
end
