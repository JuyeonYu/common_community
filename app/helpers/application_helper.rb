module ApplicationHelper
  include Pagy::Frontend

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
