class AddPortonePaymentFieldsToCreditPurchases < ActiveRecord::Migration[8.1]
  def change
    # paid_via: bank_transfer(0, 무통장) / portone_card(1, PortOne PG)
    # external_payment_id: PortOne paymentId (uuid 형태)
    add_column :credit_purchases, :paid_via, :integer, null: false, default: 0
    add_column :credit_purchases, :external_payment_id, :string
    add_column :credit_purchases, :paid_at, :datetime

    add_index :credit_purchases, :external_payment_id, unique: true
  end
end
