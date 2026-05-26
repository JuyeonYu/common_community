require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "get: 미존재 키는 nil (기본값 옵션 적용)" do
    assert_nil Setting.get("missing_key")
    assert_equal "default", Setting.get("missing_key", default: "default")
  end

  test "set: 신규 키는 생성" do
    assert_difference "Setting.count", 1 do
      Setting.set("bank_name", "신한은행")
    end
    assert_equal "신한은행", Setting.get("bank_name")
  end

  test "set: 기존 키는 갱신 (count 불변)" do
    Setting.set("bank_name", "신한은행")
    assert_no_difference "Setting.count" do
      Setting.set("bank_name", "국민은행")
    end
    assert_equal "국민은행", Setting.get("bank_name")
  end

  test "key 유일성" do
    Setting.create!(key: "k1", value: "a")
    dup = Setting.new(key: "k1", value: "b")
    assert_not dup.valid?
  end
end
