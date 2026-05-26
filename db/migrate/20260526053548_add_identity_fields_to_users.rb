class AddIdentityFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    # PortOne 본인인증 결과 — CI는 한 명의 사용자를 식별하는 88byte 해시(통신사 발급).
    # 동일 CI는 1 계정만 허용(unique). DI는 서비스별 식별로 보조.
    add_column :users, :ci, :string
    add_column :users, :di, :string
    add_column :users, :identity_verified_at, :datetime

    add_index :users, :ci, unique: true
  end
end
