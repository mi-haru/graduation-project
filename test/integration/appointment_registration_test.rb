require "test_helper"

class AppointmentRegistrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "受診登録テスト",
      email: "appointment-registration@example.com",
      password: "password123"
    )

    sign_in @user
  end

  test "新しい医療機関と受診予定を登録できる" do
    assert_difference "Hospital.count", 1 do
      assert_difference "Appointment.count", 1 do
        post appointments_path, params: {
          appointment: {
            hospital_name: "登録テストクリニック",
            department: "内科",
            appointment_date: "2026-10-01",
            appointment_time: "10:30"
          }
        }
      end
    end

    assert_redirected_to appointments_path

    hospital = @user.hospitals.find_by!(
      name: "登録テストクリニック"
    )
    appointment = hospital.appointments.sole

    assert_equal "内科", appointment.department
    assert_equal Date.new(2026, 10, 1), appointment.appointment_date
    assert_equal "10:30", appointment.appointment_time.strftime("%H:%M")

    follow_redirect!

    assert_response :success
    assert_select "[role='status']", text: "受診予定を登録しました。"
  end

  test "同名の自分の医療機関を再利用し診療科と時間は空欄で登録できる" do
    hospital = @user.hospitals.create!(
      name: "再利用クリニック"
    )

    assert_no_difference "Hospital.count" do
      assert_difference "Appointment.count", 1 do
        post appointments_path, params: {
          appointment: {
            hospital_name: "再利用クリニック",
            department: "",
            appointment_date: "2026-10-02",
            appointment_time: ""
          }
        }
      end
    end

    assert_redirected_to appointments_path

    appointment = hospital.appointments.sole

    assert appointment.department.blank?
    assert_nil appointment.appointment_time
    assert_equal Date.new(2026, 10, 2), appointment.appointment_date
  end

  test "医療機関名が空欄なら保存できない" do
    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      post appointments_path, params: {
        appointment: {
          hospital_name: "",
          department: "内科",
          appointment_date: "2026-10-01",
          appointment_time: "10:30"
        }
      }
    end

    assert_response :unprocessable_content

    assert_select "[role='alert']" do
      assert_select "li", text: /医療機関名.*入力してください/
    end

    assert_select "input[name='appointment[department]'][value='内科']"
    assert_select "input[name='appointment[appointment_date]'][value='2026-10-01']"
  end

  test "受診日が空欄なら新しい医療機関も保存されない" do
    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      post appointments_path, params: {
        appointment: {
          hospital_name: "保存されないクリニック",
          department: "眼科",
          appointment_date: "",
          appointment_time: "14:00"
        }
      }
    end

    assert_response :unprocessable_content

    assert_select "[role='alert']" do
      assert_select "li", text: /受診日.*入力してください/
    end

    assert_select "input[name='appointment[hospital_name]'][value='保存されないクリニック']"
    assert_select "input[name='appointment[department]'][value='眼科']"
  end

  test "他のユーザーの同名医療機関は再利用しない" do
    other_user = User.create!(
      nickname: "別ユーザー",
      email: "other-registration@example.com",
      password: "password123"
    )

    other_hospital = other_user.hospitals.create!(
      name: "同じ名前のクリニック"
    )

    assert_difference "Hospital.count", 1 do
      assert_difference "Appointment.count", 1 do
        post appointments_path, params: {
          appointment: {
            hospital_name: "同じ名前のクリニック",
            department: "内科",
            appointment_date: "2026-10-01",
            appointment_time: "10:30"
          }
        }
      end
    end

    assert_redirected_to appointments_path

    my_hospital = @user.hospitals.find_by!(
      name: "同じ名前のクリニック"
    )

    assert_not_equal other_hospital.id, my_hospital.id
    assert_equal 1, my_hospital.appointments.count
    assert_equal 0, other_hospital.appointments.count
  end

  test "未ログインでは登録画面を開けない" do
    sign_out @user

    get new_appointment_path

    assert_redirected_to new_user_session_path
  end

  test "未ログインでは医療機関と受診予定を登録できない" do
    sign_out @user

    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      post appointments_path, params: {
        appointment: {
          hospital_name: "未ログインのクリニック",
          appointment_date: "2026-10-01"
        }
      }
    end

    assert_redirected_to new_user_session_path
  end
end
