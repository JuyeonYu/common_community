class Admin::SettingsController < Admin::BaseController
  SETTING_KEYS = %w[ bank_name bank_account_number bank_account_holder ].freeze

  def show
    @settings = SETTING_KEYS.index_with { |k| Setting.get(k, default: "") }
  end

  def update
    SETTING_KEYS.each do |key|
      value = params.dig(:settings, key).to_s.strip
      Setting.set(key, value)
    end
    redirect_to admin_settings_path, notice: "운영 설정을 저장했습니다."
  end
end
