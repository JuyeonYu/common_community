class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create verify_otp confirm_otp ]
  before_action :set_invitation, only: %i[ new create ]

  # GET /signup/:token — 가입 정보 입력 화면
  def new
    redirect_to root_path, alert: invitation_error_message and return unless @invitation&.active?
    @user_attrs = (session[:signup_attrs].presence || {}).with_indifferent_access
    @user_attrs[:email_address] ||= @invitation.invitee_email
    @user_attrs[:name]          ||= @invitation.invitee_name
    @user_attrs[:phone]         ||= @invitation.invitee_phone
  end

  # POST /signup/:token — 입력 검증 + OTP 발송 → /signup/:token/verify
  def create
    redirect_to root_path, alert: invitation_error_message and return unless @invitation&.active?

    attrs = signup_params
    birthdate = parse_birthdate(attrs[:birthdate])

    if birthdate.nil?
      flash.now[:alert] = "생년월일을 정확히 입력해주세요."
      @user_attrs = attrs
      render :new, status: :unprocessable_entity and return
    end

    if age_at(birthdate) < User::ADULT_AGE
      flash.now[:alert] = "만 #{User::ADULT_AGE}세 이상만 가입 가능합니다."
      @user_attrs = attrs
      render :new, status: :unprocessable_entity and return
    end

    if BlacklistEntry.matches?(name: attrs[:name], phone: attrs[:phone])
      redirect_to root_path, alert: "현재 가입할 수 없습니다." and return
    end

    if User.where(email_address: attrs[:email_address].to_s.strip.downcase).exists?
      flash.now[:alert] = "이미 가입된 이메일입니다."
      @user_attrs = attrs
      render :new, status: :unprocessable_entity and return
    end

    OtpMailer.otp_email(attrs[:email_address], EmailOtp.issue(attrs[:email_address]).code).deliver_now
    session[:signup_attrs] = attrs.merge(invitation_id: @invitation.id, birthdate: birthdate.to_s).to_h
    redirect_to verify_signup_path(token: @invitation.token)
  end

  # GET /signup/:token/verify — OTP 입력 화면
  def verify_otp
    @invitation = Invitation.find_by(token: params[:token])
    redirect_to root_path and return if session[:signup_attrs].blank?
  end

  # POST /signup/:token/confirm — OTP 검증 + User 생성
  def confirm_otp
    invitation = Invitation.find_by(token: params[:token])
    redirect_to root_path, alert: invitation_error_for(invitation) and return unless invitation&.active?

    attrs = (session[:signup_attrs] || {}).with_indifferent_access
    if attrs.empty? || attrs[:invitation_id].to_i != invitation.id
      redirect_to signup_path(token: invitation.token), alert: "세션이 만료되었습니다. 처음부터 다시 시도해주세요." and return
    end

    code = params[:code].to_s.strip
    unless EmailOtp.verify(email: attrs[:email_address], code: code)
      redirect_to verify_signup_path(token: invitation.token), alert: "인증 코드가 잘못되었거나 만료되었습니다." and return
    end

    user = User.new(
      email_address: attrs[:email_address],
      name:          attrs[:name],
      phone:         attrs[:phone],
      birthdate:     attrs[:birthdate],
      inviter:       invitation.inviter
    )

    if user.save
      invitation.accept!(user)
      sign_in(user)
      session.delete(:signup_attrs)
      redirect_to root_path, notice: "가입을 환영합니다."
    else
      redirect_to signup_path(token: invitation.token), alert: user.errors.full_messages.first
    end
  end

  private
    def set_invitation
      @invitation = Invitation.find_by(token: params[:token])
    end

    def signup_params
      params.expect(user: [ :name, :birthdate, :phone, :email_address ])
    end

    def parse_birthdate(value)
      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def age_at(date)
      today = Date.current
      diff = today.year - date.year
      diff -= 1 if today.strftime("%m%d") < date.strftime("%m%d")
      diff
    end

    def invitation_error_message
      invitation_error_for(@invitation)
    end

    def invitation_error_for(invitation)
      return "유효하지 않은 초대 링크입니다." if invitation.nil?
      case invitation.status
      when :expired  then "만료된 초대 링크입니다."
      when :accepted then "이미 가입에 사용된 초대 링크입니다."
      when :canceled then "취소된 초대 링크입니다."
      else "유효하지 않은 초대 링크입니다."
      end
    end

    def sign_in(user)
      session_record = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
      Current.session = session_record
      cookies.signed.permanent[:session_id] = { value: session_record.id, httponly: true, same_site: :lax }
    end
end
