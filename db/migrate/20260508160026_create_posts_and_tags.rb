class CreatePostsAndTags < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :title, null: false
      t.integer :status, null: false, default: 0
      t.integer :views_count, null: false, default: 0
      t.timestamps
      t.index [ :status, :created_at ]
    end

    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
      t.index :name, unique: true
      t.index :slug, unique: true
    end

    create_table :post_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag,  null: false, foreign_key: true
      t.timestamps
      t.index [ :post_id, :tag_id ], unique: true
    end
  end
end
