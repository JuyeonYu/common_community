require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "이메일 주소는 strip + downcase 됨" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "이메일 주소 unique" do
    User.create!(email_address: "dup@example.com", name: "원본", password: "secret123")
    dup = User.new(email_address: "dup@example.com", name: "복제", password: "secret123")
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :email_address
  end
end
