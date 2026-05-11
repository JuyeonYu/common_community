require "test_helper"

class Admin::BlacklistEntriesControllerTest < ActionDispatch::IntegrationTest
  test "index: 비admin 차단" do
    sign_in_as(users(:one))
    get admin_blacklist_entries_path
    assert_redirected_to root_path
  end

  test "index: admin 접근" do
    sign_in_as(users(:admin))
    get admin_blacklist_entries_path
    assert_response :success
  end

  test "create: 추가" do
    sign_in_as(users(:admin))
    assert_difference "BlacklistEntry.count", 1 do
      post admin_blacklist_entries_path, params: {
        blacklist_entry: { name: "악성", phone: "010-7777-7777", reason: "사유" }
      }
    end
  end

  test "destroy: 삭제" do
    sign_in_as(users(:admin))
    entry = blacklist_entries(:spammer)
    assert_difference "BlacklistEntry.count", -1 do
      delete admin_blacklist_entry_path(entry)
    end
  end
end
