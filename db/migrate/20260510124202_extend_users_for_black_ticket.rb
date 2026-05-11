class ExtendUsersForBlackTicket < ActiveRecord::Migration[8.1]
  def change
    change_table :users do |t|
      t.date    :birthdate
      t.string  :phone
      t.string  :gender
      t.string  :residence
      t.string  :occupation
      t.string  :hobby
      t.boolean :smoking
      t.references :inviter, foreign_key: { to_table: :users }
      t.datetime :suspended_at
      t.index :phone, unique: true, where: "phone IS NOT NULL"
    end
  end
end
