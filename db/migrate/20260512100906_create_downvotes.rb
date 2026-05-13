class CreateDownvotes < ActiveRecord::Migration[8.1]
  def change
    create_table :downvotes do |t|
      t.references :from_user,   null: false, foreign_key: { to_table: :users }
      t.references :to_user,     null: false, foreign_key: { to_table: :users }
      t.references :red_connect, null: false, foreign_key: true
      t.integer :kind, null: false        # 0:false_info 1:abusive 2:incompatible
      t.text :comment
      t.timestamps
    end
    add_index :downvotes, [ :red_connect_id, :from_user_id ], unique: true
    add_index :downvotes, [ :to_user_id, :kind ]
  end
end
