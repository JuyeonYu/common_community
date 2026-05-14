class UsersController < ApplicationController
  # 멘션 자동완성용 닉네임 검색. 최대 5명, prefix 매칭.
  def search
    q = params[:q].to_s.strip
    users = if q.length >= 1
      User.where("nickname ILIKE ?", "#{User.sanitize_sql_like(q)}%")
          .where.not(id: Current.user.id)
          .where.not(nickname: nil)
          .order(:nickname)
          .limit(5)
    else
      User.none
    end

    render json: users.map { |u| { id: u.id, nickname: u.nickname, avatar_url: u.avatar_url } }
  end
end
