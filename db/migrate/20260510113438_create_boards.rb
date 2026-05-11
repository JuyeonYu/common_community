class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards do |t|
      t.string  :name, null: false
      t.string  :slug, null: false
      t.text    :description
      t.integer :position, null: false, default: 0
      t.jsonb   :allowed_prefixes, null: false, default: []
      t.integer :write_permission, null: false, default: 0
      t.timestamps
      t.index :slug, unique: true
      t.index :position
    end
  end
end
