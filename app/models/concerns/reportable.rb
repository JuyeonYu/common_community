module Reportable
  extend ActiveSupport::Concern

  included do
    has_many :reports, as: :reportable, dependent: :destroy
  end

  def reported_by?(user)
    return false if user.blank?
    reports.exists?(reporter_id: user.id)
  end
end
