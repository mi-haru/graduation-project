require "test_helper"

class HomeNextAppointmentTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "次回受診テスト",
      email: "home-next-appointment@example.com",
      password: "password123"
    )

    sign_in @user
  end

  test "自分の受診予定の中から最も近い1件だけを表示する" do
    travel_to Time.zone.local(2026, 10, 1, 12, 0, 0) do
      hospital = @user.hospitals.create!(
        name: "次回表示クリニック"
      )

      hospital.appointments.create!(
        department: "内科",
        appointment_date: Date.current,
        appointment_time: "14:00"
      )

      later_hospital = @user.hospitals.create!(
        name: "翌日のクリニック"
      )

      later_hospital.appointments.create!(
        appointment_date: Date.tomorrow,
        appointment_time: "09:00"
      )

      other_user = User.create!(
        nickname: "別ユーザー",
        email: "other-home-next-appointment@example.com",
        password: "password123"
      )

      other_hospital = other_user.hospitals.create!(
        name: "別ユーザーのクリニック"
      )

      other_hospital.appointments.create!(
        appointment_date: Date.current,
        appointment_time: "13:00"
      )

      get home_path

      assert_response :success
      assert_includes response.body, "次回表示クリニック"
      assert_includes response.body, "内科"
      assert_includes response.body, "2026年10月1日"
      assert_includes response.body, "14:00"

      assert_not_includes response.body, "翌日のクリニック"
      assert_not_includes response.body, "別ユーザーのクリニック"

      assert_select "a[href=?]",
                    new_appointment_path,
                    text: "受診予定を登録する",
                    count: 1
    end
  end

  test "過去の予定を除外して今日の未経過の予定を表示する" do
    travel_to Time.zone.local(2026, 10, 1, 12, 0, 0) do
      [
        [ "昨日のクリニック", Date.yesterday, "15:00" ],
        [ "今朝のクリニック", Date.current, "10:00" ],
        [ "今日午後のクリニック", Date.current, "14:00" ]
      ].each do |name, date, time|
        hospital = @user.hospitals.create!(name: name)

        hospital.appointments.create!(
          appointment_date: date,
          appointment_time: time
        )
      end

      get home_path

      assert_response :success
      assert_includes response.body, "今日午後のクリニック"
      assert_includes response.body, "14:00"
      assert_not_includes response.body, "昨日のクリニック"
      assert_not_includes response.body, "今朝のクリニック"
    end
  end

  test "同じ日なら時間未設定より時間指定ありの予定を優先する" do
    travel_to Time.zone.local(2026, 10, 1, 12, 0, 0) do
      unspecified_hospital = @user.hospitals.create!(
        name: "時間未設定クリニック"
      )
      unspecified_hospital.appointments.create!(
        appointment_date: Date.current,
        appointment_time: nil
      )

      timed_hospital = @user.hospitals.create!(
        name: "午後のクリニック"
      )
      timed_hospital.appointments.create!(
        appointment_date: Date.current,
        appointment_time: "14:00"
      )

      get home_path

      assert_response :success
      assert_includes response.body, "午後のクリニック"
      assert_includes response.body, "14:00"
      assert_not_includes response.body, "時間未設定クリニック"
    end
  end

  test "今日の時間未設定の予定を明日の予定より優先する" do
    travel_to Time.zone.local(2026, 10, 1, 23, 0, 0) do
      today_hospital = @user.hospitals.create!(
        name: "今日の時間未設定クリニック"
      )
      today_hospital.appointments.create!(
        appointment_date: Date.current,
        appointment_time: nil
      )

      tomorrow_hospital = @user.hospitals.create!(
        name: "明日のクリニック"
      )
      tomorrow_hospital.appointments.create!(
        appointment_date: Date.tomorrow,
        appointment_time: "09:00"
      )

      get home_path

      assert_response :success
      assert_includes response.body, "今日の時間未設定クリニック"
      assert_includes response.body, "時間未設定"
      assert_not_includes response.body, "明日のクリニック"
    end
  end

  test "過去の予定しかなければ次回の予定がない案内を表示する" do
    travel_to Time.zone.local(2026, 10, 1, 12, 0, 0) do
      hospital = @user.hospitals.create!(
        name: "過去のクリニック"
      )

      hospital.appointments.create!(
        appointment_date: Date.yesterday,
        appointment_time: nil
      )

      hospital.appointments.create!(
        appointment_date: Date.current,
        appointment_time: "10:00"
      )

      get home_path

      assert_response :success
      assert_includes response.body, "次回の受診予定はありません"
      assert_not_includes response.body, "過去のクリニック"

      assert_select "a[href=?]",
                    new_appointment_path,
                    text: "受診予定を登録する",
                    count: 1
    end
  end

  test "自分に予定がなければ他のユーザーの予定を表示しない" do
    travel_to Time.zone.local(2026, 10, 1, 12, 0, 0) do
      other_user = User.create!(
        nickname: "別ユーザー",
        email: "other-next-appointment-only@example.com",
        password: "password123"
      )

      hospital = other_user.hospitals.create!(
        name: "他人の未来クリニック"
      )

      hospital.appointments.create!(
        appointment_date: Date.tomorrow,
        appointment_time: "09:00"
      )

      get home_path

      assert_response :success
      assert_includes response.body, "次回の受診予定はありません"
      assert_not_includes response.body, "他人の未来クリニック"
    end
  end

  test "日本時間で朝の予定を午後の予定より先に表示する" do
    travel_to Time.zone.local(2026, 10, 1, 6, 0, 0) do
      [
        [ "午後のクリニック", "14:00" ],
        [ "朝のクリニック", "08:00" ]
      ].each do |name, time|
        hospital = @user.hospitals.create!(name: name)

        hospital.appointments.create!(
          appointment_date: Date.current,
          appointment_time: time
        )
      end

      get home_path

      assert_response :success
      assert_includes response.body, "朝のクリニック"
      assert_includes response.body, "08:00"
      assert_not_includes response.body, "午後のクリニック"
    end
  end
end
