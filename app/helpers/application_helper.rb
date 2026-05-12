module ApplicationHelper
  include Pagy::Frontend

  def like_url_for(likeable)
    case likeable
    when Post    then post_like_path(likeable)
    when Comment then comment_like_path(likeable)
    end
  end

  # 사용자 아바타 이미지. 업로드 우선, 없으면 외부 avatar_url, 둘 다 없으면 nil.
  def avatar_image(user, class: "")
    css_class = binding.local_variable_get(:class)
    return unless user
    if user.avatar.attached?
      image_tag user.avatar, class: css_class, alt: user.name
    elsif user.avatar_url.present?
      image_tag user.avatar_url, class: css_class, alt: user.name
    end
  end
end
