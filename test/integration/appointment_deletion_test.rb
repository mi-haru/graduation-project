require "test_helper"

class AppointmentDeletionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "受診削除テスト",
      email: "appointment-deletion@example.com",
      password: "password123"
    )

    @hospital = @user.hospitals.create!(
      name: "削除テストクリニック"
    )

    @appointment = @hospital.appointments.create!(
      department: "内科",
      appointment_date: Date.new(2026, 10, 1),
      appointment_time: "10:30"
    )

    @other_appointment = @hospital.appointments.create!(
      department: "眼科",
      appointment_date: Date.new(2026, 10, 15),
      appointment_time: "14:00"
    )
  end

  test "自分の予定だけを削除して一覧へ戻る" do
    sign_in @user

    remaining_attributes = @other_appointment.attributes

    assert_no_difference "Hospital.count" do
      assert_difference "Appointment.count", -1 do
        delete appointment_path(@appointment)
      end
    end

    assert_response :see_other
    assert_redirected_to appointments_path

    assert_not Appointment.exists?(@appointment.id)
    assert Hospital.exists?(@hospital.id)
    assert_equal remaining_attributes, @other_appointment.reload.attributes

    follow_redirect!

    assert_response :success
    assert_select "[role='status']", text: "受診予定を削除しました。"

    assert_select "a[href=?]", edit_appointment_path(@appointment), count: 0
    assert_select "a[href=?]",
                  edit_appointment_path(@other_appointment),
                  text: "詳細・編集",
                  count: 1
  end

  test "未ログインでは受診予定を削除できない" do
    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      delete appointment_path(@appointment)
    end

    assert_redirected_to new_user_session_path

    assert Appointment.exists?(@appointment.id)
    assert Appointment.exists?(@other_appointment.id)
    assert Hospital.exists?(@hospital.id)
  end

  test "他のユーザーの受診予定は削除できない" do
    other_user = User.create!(
      nickname: "別ユーザー",
      email: "other-appointment-deletion@example.com",
      password: "password123"
    )

    sign_in other_user

    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      begin
        delete appointment_path(@appointment)
        assert_response :not_found
      rescue ActiveRecord::RecordNotFound
        assert true
      end
    end

    assert Appointment.exists?(@appointment.id)
    assert Appointment.exists?(@other_appointment.id)
    assert Hospital.exists?(@hospital.id)
  end
end
