require "test_helper"

class SeedEmailTest < ActiveSupport::TestCase
  test "이메일 normalize: strip + downcase" do
    se = SeedEmail.create!(email: "  Founder2@Example.COM  ")
    assert_equal "founder2@example.com", se.email
  end

  test "unique" do
    dup = SeedEmail.new(email: seed_emails(:founder).email)
    assert_not dup.valid?
  end

  test "whitelisted?" do
    assert SeedEmail.whitelisted?("founder@example.com")
    assert SeedEmail.whitelisted?("  FOUNDER@example.com  ")
    assert_not SeedEmail.whitelisted?("missing@example.com")
  end

  test "잘못된 이메일 형식" do
    se = SeedEmail.new(email: "not-an-email")
    assert_not se.valid?
  end
end
