module TimeHelper
  # 작성 시점을 상대 시간(방금/n분 전/n시간 전/n일 전/n개월 전)으로 표기한다.
  # 1년이 지나면 절대 날짜로 떨어진다. with_time이면 그때 시:분까지 포함한다(댓글용).
  # 항상 datetime 속성을 가진 <time> 태그로 감싸 클라이언트 재해석 여지를 남긴다.
  def relative_time(time, with_time: false)
    return if time.blank?

    seconds = Time.current - time
    label =
      if seconds < 1.minute
        t("time.relative.just_now")
      elsif seconds < 1.hour
        t("time.relative.minutes", n: (seconds / 60).to_i)
      elsif seconds < 1.day
        t("time.relative.hours", n: (seconds / 3600).to_i)
      elsif seconds < 30.days
        t("time.relative.days", n: (seconds / 86_400).to_i)
      elsif seconds < 365.days
        t("time.relative.months", n: (seconds / (30 * 86_400)).to_i)
      else
        l(time, format: with_time ? :ymd_hm : :ymd)
      end

    tag.time(label, datetime: time.iso8601)
  end
end
