class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :comments }
      t.text    :body, null: false
      t.integer :status, null: false, default: 0
      t.timestamps
      t.index [ :post_id, :parent_id, :created_at ]
    end
  end
end
