class CreateMatchExposures < ActiveRecord::Migration[8.1]
  # 매칭 우선순위 계산용 — viewer가 target을 매칭 카드에서 본 이력.
  # 1순위: 이전에 노출 없는 사용자 정렬.
  def change
    create_table :match_exposures do |t|
      t.references :viewer, null: false, foreign_key: { to_table: :users }
      t.references :target, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :match_exposures, [ :viewer_id, :target_id ], unique: true
  end
end
