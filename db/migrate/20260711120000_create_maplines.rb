class CreateMaplines < ActiveRecord::Migration[8.0]
  def change
    create_table :maplines do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.string :status, null: false, default: "draft"

      # Vue initiale de la carte (défauts : vue monde)
      t.float :center_lng, null: false, default: 0.0
      t.float :center_lat, null: false, default: 20.0
      t.float :zoom, null: false, default: 1.5

      t.datetime :published_at

      t.timestamps
    end

    add_index :maplines, :slug, unique: true
  end
end
