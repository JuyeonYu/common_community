module IconsHelper
  # 인라인 SVG 아이콘 렌더. Heroicons outline v2 기반.
  # 사용: <%= icon :bell, class: "h-5 w-5" %>
  def icon(name, **opts)
    klass = opts.delete(:class) || "h-5 w-5"
    render partial: "icons/#{name}", locals: { klass: klass }
  end
end
