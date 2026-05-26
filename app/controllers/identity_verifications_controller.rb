class IdentityVerificationsController < ApplicationController
  # 본인인증 진입 — 매칭 활성화 전에 강제 (matching_ready?에 결합).
  def new
    @identity_verification_id = "identity-#{SecureRandom.uuid}"
  end

  # PortOne JS SDK가 성공 콜백 후 이 액션에 paymentless POST.
  # 서버에서 PortOne REST로 검증 → User에 ci/di/name/birth_date/gender 저장.
  def create
    id = params[:identity_verification_id].to_s
    if id.blank?
      redirect_to new_identity_verification_path, alert: "본인인증 ID가 누락되었습니다." and return
    end

    code, body = PortOne.get_identity_verification(id)
    unless code == 200 && body["status"] == "VERIFIED"
      redirect_to new_identity_verification_path,
        alert: "본인인증 결과 조회 실패: #{body["message"] || code}" and return
    end

    info = body["verifiedCustomer"] || {}
    ci   = info["ci"].presence
    di   = info["di"].presence

    if ci.blank?
      redirect_to new_identity_verification_path,
        alert: "본인인증 결과에 CI가 없습니다. 다시 시도해주세요." and return
    end

    # CI 중복 검사 — 다른 사용자가 이미 보유 시 차단.
    other = User.where.not(id: Current.user.id).find_by(ci: ci)
    if other.present?
      redirect_to root_path,
        alert: "이미 다른 계정에 등록된 본인인증 정보입니다." and return
    end

    Current.user.update!(
      ci: ci, di: di,
      name: info["name"].presence || Current.user.name,
      birth_date: parse_birth(info["birthDate"]) || Current.user.birth_date,
      gender: map_gender(info["gender"]) || Current.user.gender,
      identity_verified_at: Time.current
    )

    redirect_to matching_path, notice: "본인인증이 완료되었습니다."
  end

  private
    def parse_birth(str)
      return nil if str.blank?
      Date.parse(str)
    rescue ArgumentError
      nil
    end

    # PortOne 응답: "MALE" / "FEMALE" / "OTHER" → User enum male/female.
    def map_gender(value)
      case value.to_s.upcase
      when "MALE"   then :male
      when "FEMALE" then :female
      end
    end
end
