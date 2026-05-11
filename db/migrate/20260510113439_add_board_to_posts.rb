class AddBoardToPosts < ActiveRecord::Migration[8.1]
  def up
    # 1. 기본 게시판 시드 (자유)
    execute <<~SQL
      INSERT INTO boards (name, slug, position, allowed_prefixes, write_permission, created_at, updated_at)
      VALUES ('자유', 'free', 0, '[]'::jsonb, 0, NOW(), NOW())
      ON CONFLICT (slug) DO NOTHING
    SQL

    # 2. posts에 board_id (nullable로 추가) + prefix 컬럼
    add_reference :posts, :board, foreign_key: true, null: true
    add_column :posts, :prefix, :string

    # 3. 기존 모든 post를 자유 게시판으로 backfill
    execute <<~SQL
      UPDATE posts
      SET board_id = (SELECT id FROM boards WHERE slug = 'free' LIMIT 1)
      WHERE board_id IS NULL
    SQL

    # 4. NOT NULL 제약 적용
    change_column_null :posts, :board_id, false
  end

  def down
    remove_column :posts, :prefix
    remove_reference :posts, :board, foreign_key: true
    execute "DELETE FROM boards WHERE slug = 'free'"
  end
end
