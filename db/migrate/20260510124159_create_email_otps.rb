class CreateEmailOtps < ActiveRecord::Migration[8.1]
  def change
    create_table :email_otps do |t|
      t.string   :email,       null: false
      t.string   :code,        null: false
      t.datetime :expires_at,  null: false
      t.datetime :consumed_at
      t.timestamps
      t.index [ :email, :code ]
      t.index :expires_at
    end
  end
end
