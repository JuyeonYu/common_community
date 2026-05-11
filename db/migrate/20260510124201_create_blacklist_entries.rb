class CreateBlacklistEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :blacklist_entries do |t|
      t.string     :name,  null: false
      t.string     :phone, null: false
      t.text       :reason
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
      t.index [ :name, :phone ], unique: true
    end
  end
end
