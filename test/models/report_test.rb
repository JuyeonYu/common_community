require "test_helper"

class ReportTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @post = posts(:welcome)
  end

  test "reason 필수" do
    r = Report.new(reporter: @user, reportable: @post, reason: "")
    assert_not r.valid?
    assert r.errors[:reason].any?
  end

  test "reason 길이 제한 1000자" do
    r = Report.new(reporter: @user, reportable: @post, reason: "ㄱ" * 1_001)
    assert_not r.valid?
  end

  test "기본 status는 pending" do
    r = Report.create!(reporter: @user, reportable: @post, reason: "테스트")
    assert r.pending?
  end

  test "Reportable concern: reported_by?" do
    assert @post.reported_by?(users(:two))
    assert_not @post.reported_by?(users(:one))
    assert_not @post.reported_by?(nil)
  end

  test "post 삭제 시 reports cascade" do
    fresh = Post.create!(user: users(:one), board: boards(:free), title: "임시", body: "<p>x</p>")
    Report.create!(reporter: @user, reportable: fresh, reason: "test")
    assert_difference "Report.count", -1 do
      fresh.destroy
    end
  end
end
