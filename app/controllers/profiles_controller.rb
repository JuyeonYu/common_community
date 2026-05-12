class ProfilesController < ApplicationController
  before_action :set_user
  before_action :require_self, only: %i[ edit update ]

  def show
  end

  def edit
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path(@user), notice: "프로필이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def require_self
      return if Current.user&.id == @user.id
      redirect_to profile_path(@user), alert: "권한이 없습니다."
    end

    def profile_params
      params.expect(user: [
        :name, :nickname, :bio, :avatar,
        :hobby, :residence_area, :job_title, :smoking, :birth_date, :gender,
        { notification_preferences: [ :web_push ] }
      ])
    end
end
