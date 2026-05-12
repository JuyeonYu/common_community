class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      # 초대를 발행한 사용자.
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      # URL용 긴 토큰(기존 호환). 현재는 code와 동일 값으로 채워두고 추후 분리 여지.
      t.string :token, null: false
      # 사용자 입력용 8자 코드. URL `/invitations/:code` 와 수동 입력 양쪽에 사용.
      t.string :code, null: false
      # 12시간 후 만료.
      t.datetime :expires_at, null: false
      # 0:pending 1:accepted 2:expired 3:cancelled
      t.integer :status, null: false, default: 0
      # Phase D RedTicket 생성 시 활용. 초대 발급 시점에 적을 수도 있고 빈 값일 수도.
      t.text :recommendation_comment
      # 초대 코드를 적용한 사용자 (1회용 — accepted 후 비어 있지 않음).
      t.references :accepted_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
    add_index :invitations, :token, unique: true
    add_index :invitations, :code, unique: true
    add_index :invitations, [ :inviter_id, :created_at ]
  end
end
