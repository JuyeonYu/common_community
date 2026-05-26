class CreateCreditPurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :package_key,     null: false
      t.integer :declared_amount, null: false
      t.string  :declared_name,   null: false
      t.integer :status,          null: false, default: 0
      # 어드민이 승인/거절 처리 시 채움. processed_by는 다른 admin User를 참조 — User 테이블 직접 FK.
      t.references :processed_by, foreign_key: { to_table: :users }
      t.datetime :processed_at
      t.text :admin_memo

      t.timestamps
    end
    add_index :credit_purchases, %i[ status created_at ]
  end
end
