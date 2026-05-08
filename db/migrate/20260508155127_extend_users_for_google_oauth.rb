class ExtendUsersForGoogleOauth < ActiveRecord::Migration[8.1]
  def change
    change_table :users do |t|
      t.string  :google_uid
      t.string  :name
      t.string  :avatar_url
      t.boolean :admin, default: false, null: false
      t.text    :bio
      t.index :google_uid, unique: true
    end

    change_column_null :users, :password_digest, true
  end
end
