class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.string     :token, null: false
      t.string     :invitee_name,  null: false
      t.string     :invitee_phone, null: false
      t.string     :invitee_email, null: false
      t.datetime   :expires_at,    null: false
      t.datetime   :accepted_at
      t.datetime   :canceled_at
      t.references :accepted_user, foreign_key: { to_table: :users }
      t.timestamps
      t.index :token, unique: true
      t.index :expires_at
      t.index :invitee_email
    end
  end
end
