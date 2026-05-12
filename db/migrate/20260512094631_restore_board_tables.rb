class RestoreBoardTables < ActiveRecord::Migration[8.1]
  # Phase D-0: Phase A에서 폐기했던 게시판 도메인 6개 테이블을 복원.
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

    create_table :comments do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :comments }
      t.text    :body, null: false
      t.integer :status, null: false, default: 0
      t.timestamps
      t.index [ :post_id, :parent_id, :created_at ]
    end

    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :likeable, polymorphic: true, null: false
      t.timestamps
      t.index [ :user_id, :likeable_type, :likeable_id ], unique: true, name: "index_likes_on_user_and_likeable"
    end

    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, polymorphic: true, null: false
      t.text       :reason, null: false
      t.integer    :status, null: false, default: 0
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime   :resolved_at
      t.timestamps
      t.index [ :reportable_type, :reportable_id, :status ]
      t.index [ :status, :created_at ]
    end
  end
end
