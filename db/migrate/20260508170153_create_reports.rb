class CreateReports < ActiveRecord::Migration[8.1]
  def change
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
