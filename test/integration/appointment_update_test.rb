require "test_helper"

class AppointmentUpdateTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      nickname: "受診編集テスト",
      email: "appointment-update@example.com",
      password: "password123"
    )

    @hospital = @user.hospitals.create!(
      name: "編集前クリニック"
    )

    @appointment = @hospital.appointments.create!(
      department: "内科",
      appointment_date: Date.new(2026, 10, 1),
      appointment_time: "10:30"
    )

    sign_in @user
  end

  test "詳細編集画面に登録済みの内容を表示する" do
    get edit_appointment_path(@appointment)

    assert_response :success

    assert_select "input[name='appointment[hospital_name]'][value='編集前クリニック']"
    assert_select "input[name='appointment[department]'][value='内科']"
    assert_select "input[name='appointment[appointment_date]'][value='2026-10-01']"

    assert_select "input[name='appointment[appointment_time]']" do |inputs|
      assert_match(/\A10:30(?::00(?:\.0+)?)?\z/, inputs.first["value"])
    end

    assert_select "input[type='submit'][value='更新する']"
  end

  test "診療科と受診日時を更新できる" do
    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      patch appointment_path(@appointment), params: {
        appointment: {
          hospital_name: @hospital.name,
          department: "眼科",
          appointment_date: "2026-10-15",
          appointment_time: "14:00"
        }
      }
    end

    assert_response :see_other
    assert_redirected_to appointments_path

    @appointment.reload

    assert_equal @hospital.id, @appointment.hospital_id
    assert_equal "眼科", @appointment.department
    assert_equal Date.new(2026, 10, 15), @appointment.appointment_date
    assert_equal "14:00", @appointment.appointment_time.strftime("%H:%M")

    follow_redirect!

    assert_response :success
    assert_select "[role='status']", text: "受診予定を更新しました。"
  end

  test "医療機関名を変更しても同じ医療機関の別の予定は変わらない" do
    other_appointment = @hospital.appointments.create!(
      department: "皮膚科",
      appointment_date: Date.new(2026, 10, 20),
      appointment_time: "11:00"
    )

    assert_difference "Hospital.count", 1 do
      assert_no_difference "Appointment.count" do
        patch appointment_path(@appointment), params: {
          appointment: {
            hospital_name: "変更後クリニック",
            department: "内科",
            appointment_date: "2026-10-01",
            appointment_time: "10:30"
          }
        }
      end
    end

    assert_redirected_to appointments_path

    @appointment.reload
    other_appointment.reload

    assert_equal "変更後クリニック", @appointment.hospital.name
    assert_equal @user.id, @appointment.hospital.user_id
    assert_not_equal @hospital.id, @appointment.hospital_id

    assert_equal @hospital.id, other_appointment.hospital_id
    assert_equal "編集前クリニック", @hospital.reload.name
    assert_equal "皮膚科", other_appointment.department
    assert_equal Date.new(2026, 10, 20), other_appointment.appointment_date
    assert_equal "11:00", other_appointment.appointment_time.strftime("%H:%M")
  end

  test "変更先が自分の登録済み医療機関なら再利用する" do
    existing_hospital = @user.hospitals.create!(
      name: "登録済みクリニック"
    )

    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      patch appointment_path(@appointment), params: {
        appointment: {
          hospital_name: existing_hospital.name,
          department: "内科",
          appointment_date: "2026-10-01",
          appointment_time: "10:30"
        }
      }
    end

    assert_redirected_to appointments_path
    assert_equal existing_hospital.id, @appointment.reload.hospital_id
    assert_equal "編集前クリニック", @hospital.reload.name
  end

  test "受診日が空欄なら変更を保存せず新しい医療機関も作らない" do
    original_attributes = @appointment.reload.attributes

    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      patch appointment_path(@appointment), params: {
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

    assert_equal original_attributes, @appointment.reload.attributes
    assert_equal "編集前クリニック", @hospital.reload.name
  end

  test "医療機関名が空欄なら変更を保存しない" do
    original_attributes = @appointment.reload.attributes

    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      patch appointment_path(@appointment), params: {
        appointment: {
          hospital_name: "",
          department: "眼科",
          appointment_date: "2026-10-15",
          appointment_time: "14:00"
        }
      }
    end

    assert_response :unprocessable_content

    assert_select "[role='alert']" do
      assert_select "li", text: /医療機関名.*入力してください/
    end

    assert_select "input[name='appointment[department]'][value='眼科']"

    assert_equal original_attributes, @appointment.reload.attributes
    assert_equal "編集前クリニック", @hospital.reload.name
  end

  test "他のユーザーの受診予定は編集画面を開けない" do
    other_user = User.create!(
      nickname: "別ユーザー",
      email: "other-appointment-edit@example.com",
      password: "password123"
    )

    sign_in other_user

    begin
      get edit_appointment_path(@appointment)
      assert_response :not_found
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "他のユーザーの受診予定は更新できない" do
    other_user = User.create!(
      nickname: "別ユーザー",
      email: "other-appointment-update@example.com",
      password: "password123"
    )

    original_attributes = @appointment.reload.attributes

    sign_in other_user

    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      begin
        patch appointment_path(@appointment), params: {
          appointment: {
            hospital_name: "変更できないクリニック",
            department: "眼科",
            appointment_date: "2026-10-15",
            appointment_time: "14:00"
          }
        }

        assert_response :not_found
      rescue ActiveRecord::RecordNotFound
        assert true
      end
    end

    assert_equal original_attributes, @appointment.reload.attributes
    assert_equal "編集前クリニック", @hospital.reload.name
  end

  test "未ログインでは編集画面を開けない" do
    sign_out @user

    get edit_appointment_path(@appointment)

    assert_redirected_to new_user_session_path
  end

  test "未ログインでは受診予定を更新できない" do
    original_attributes = @appointment.reload.attributes

    sign_out @user

    assert_no_difference [ "Hospital.count", "Appointment.count" ] do
      patch appointment_path(@appointment), params: {
        appointment: {
          hospital_name: "変更できないクリニック",
          department: "眼科",
          appointment_date: "2026-10-15",
          appointment_time: "14:00"
        }
      }
    end

    assert_redirected_to new_user_session_path
    assert_equal original_attributes, @appointment.reload.attributes
    assert_equal "編集前クリニック", @hospital.reload.name
  end
end
