require "test_helper"

class TimeHelperTest < ActionView::TestCase
  # <time> 태그 안쪽 표시 문자열만 추출 (datetime 속성과 분리해서 검증)
  def label(html)
    html[/>([^<]*)<\/time>/, 1]
  end

  test "1분 미만은 방금" do
    assert_equal "방금", label(relative_time(Time.current))
  end

  test "분 단위" do
    assert_equal "5분 전", label(relative_time(5.minutes.ago))
  end

  test "시간 단위" do
    assert_equal "3시간 전", label(relative_time(3.hours.ago))
  end

  test "일 단위" do
    assert_equal "2일 전", label(relative_time(2.days.ago))
  end

  test "개월 단위" do
    assert_equal "2개월 전", label(relative_time(60.days.ago))
  end

  test "1년 이상은 절대 날짜(yyyy.mm.dd), 시:분 미포함" do
    t = Time.zone.local(2020, 3, 5, 14, 30)
    assert_equal "2020.03.05", label(relative_time(t))
  end

  test "with_time이면 절대 표기에 시:분 포함" do
    t = Time.zone.local(2020, 3, 5, 14, 30)
    assert_equal "2020.03.05 14:30", label(relative_time(t, with_time: true))
  end

  test "datetime 속성을 가진 time 태그로 감싼다" do
    html = relative_time(1.hour.ago)
    assert_match(/\A<time datetime="[^"]+">/, html)
  end

  test "nil이면 nil" do
    assert_nil relative_time(nil)
  end
end
