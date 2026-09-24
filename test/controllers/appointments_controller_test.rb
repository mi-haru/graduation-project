require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "受診予定テスト",
      email: "appointment-test@example.com",
      password: "password123"
    )

    other_user = User.create!(
      nickname: "別ユーザー",
      email: "other-appointment-test@example.com",
      password: "password123"
    )

    hospital = @user.hospitals.create!(
      name: "自分のクリニック"
    )

    other_hospital = other_user.hospitals.create!(
      name: "別ユーザーのクリニック"
    )

    @appointment = hospital.appointments.create!(
      department: "内科",
      appointment_date: Date.new(2026, 10, 1),
      appointment_time: "10:30"
    )

    other_hospital.appointments.create!(
      department: "皮膚科",
      appointment_date: Date.new(2026, 10, 2),
      appointment_time: "14:00"
    )
  end

  test "未ログインではログイン画面へ移動する" do
    get appointments_path

    assert_redirected_to new_user_session_path
  end

  test "自分の受診予定だけを表示する" do
    sign_in @user
    get appointments_path

    assert_response :success
    assert_includes response.body, "自分のクリニック"
    assert_includes response.body, "内科"
    assert_includes response.body, "2026年10月1日"
    assert_includes response.body, "10:30"

    assert_not_includes response.body, "別ユーザーのクリニック"
    assert_not_includes response.body, "皮膚科"
  end

  test "診療科と時間が未登録でも表示できる" do
    @appointment.update!(
      department: nil,
      appointment_time: nil
    )

    sign_in @user
    get appointments_path

    assert_response :success
    assert_includes response.body, "自分のクリニック"
    assert_includes response.body, "時間未設定"
    assert_not_includes response.body, "内科"
  end

  test "受診予定が複数あっても各カードを1回だけ表示する" do
    second_hospital = @user.hospitals.create!(
      name: "2つ目のクリニック"
    )

    second_hospital.appointments.create!(
      appointment_date: Date.new(2026, 10, 3)
    )

    sign_in @user
    get appointments_path

    assert_response :success
    assert_select "h2", text: "自分のクリニック", count: 1
    assert_select "h2", text: "2つ目のクリニック", count: 1
  end

  test "自分の受診予定がなければ未登録の案内を表示する" do
    @appointment.destroy!

    sign_in @user
    get appointments_path

    assert_response :success
    assert_includes response.body, "受診予定はまだありません"
    assert_not_includes response.body, "別ユーザーのクリニック"
  end

  test "一覧に各受診予定の詳細編集リンクを表示する" do
    second_appointment = @appointment.hospital.appointments.create!(
      appointment_date: Date.new(2026, 10, 15)
    )

    sign_in @user
    get appointments_path

    assert_response :success

    [ @appointment, second_appointment ].each do |appointment|
      assert_select "a[href=?]",
                    edit_appointment_path(appointment),
                    text: "詳細・編集",
                    count: 1
    end
  end
end
