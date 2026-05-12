class MatchExposure < ApplicationRecord
  belongs_to :viewer, class_name: "User"
  belongs_to :target, class_name: "User"

  validates :viewer_id, uniqueness: { scope: :target_id }
end
