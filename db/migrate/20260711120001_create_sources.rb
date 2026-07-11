class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources do |t|
      t.references :mapline, null: false, foreign_key: true
      t.string :title, null: false
      t.string :url
      t.string :author
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
