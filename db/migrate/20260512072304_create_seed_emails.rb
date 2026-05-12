class CreateSeedEmails < ActiveRecord::Migration[8.1]
  # 시드 사용자 화이트리스트. 이 이메일로 첫 Google 로그인 시 초대 없이도 자동 활성화 + seed=true.
  def change
    create_table :seed_emails do |t|
      t.string :email, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
    add_index :seed_emails, :email, unique: true
  end
end
