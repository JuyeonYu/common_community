class Report < ApplicationRecord
  belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true
  belongs_to :resolved_by, class_name: "User", optional: true

  enum :status, { pending: 0, resolved: 1, dismissed: 2 }

  validates :reason, presence: true, length: { maximum: 1_000 }

  scope :recent, -> { order(created_at: :desc) }
end
