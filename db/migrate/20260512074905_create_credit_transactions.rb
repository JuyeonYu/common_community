class CreateCreditTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount, null: false          # 음수=차감, 양수=충전
      t.integer :kind, null: false            # enum (signup_bonus / admin_grant / spend / ...)
      t.references :related, polymorphic: true
      t.text :memo

      t.timestamps
    end
    add_index :credit_transactions, [ :user_id, :created_at ]
  end
end
