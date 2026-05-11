require "test_helper"

class BlacklistEntryTest < ActiveSupport::TestCase
  test "phone normalization (숫자만)" do
    e = BlacklistEntry.new(name: "홍길동", phone: "010-1234-5678")
    e.valid?
    assert_equal "01012345678", e.phone
  end

  test "matches?: 이름+휴대폰 일치 시 true" do
    assert BlacklistEntry.matches?(name: "스팸유저", phone: "010-9999-8888")
    assert_not BlacklistEntry.matches?(name: "다른사람", phone: "010-9999-8888")
    assert_not BlacklistEntry.matches?(name: "스팸유저", phone: "010-0000-0000")
  end
end
