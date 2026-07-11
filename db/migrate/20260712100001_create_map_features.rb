class CreateMapFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :map_features do |t|
      t.references :mapline, null: false, foreign_key: true
      # area / line / arrow / point / label — identité stable dans le temps.
      t.string :feature_type, null: false
      t.string :name
      t.integer :z_index, null: false, default: 0
      # fill, fillOpacity, stroke, strokeWidth, strokeDash, icon, textSize…
      t.json :style, null: false, default: {}

      t.timestamps
    end
  end
end
