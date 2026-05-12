class AddProfileAndScoreFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :nickname, :string
    add_column :users, :hobby, :text           # 해시태그 N개. 콤마/공백 분리 입력 후 정규화
    add_column :users, :residence_area, :integer # enum (17개 시도)
    add_column :users, :job_title, :string     # 자유 입력 필수
    add_column :users, :smoking, :integer      # enum (smokes/non_smoker/sometimes)
    add_column :users, :birth_date, :date
    add_column :users, :gender, :integer       # enum (male/female/other)
    add_column :users, :ticket_score, :integer, default: 10, null: false
    add_column :users, :ticket_credits, :integer, default: 0, null: false
    add_column :users, :suspended_until, :datetime
    add_column :users, :notification_preferences, :jsonb, default: {}, null: false

    add_index :users, :nickname, unique: true, where: "nickname IS NOT NULL"
  end
end
