class CreateFeatureStates < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_states do |t|
      t.references :map_feature, null: false, foreign_key: true
      t.references :key_date, null: false, foreign_key: true
      # GeoJSON : Polygon/MultiPolygon (area), LineString (line/arrow), Point (point/label).
      t.json :geometry, null: false
      t.json :style_override                 # fusionné par-dessus map_feature.style
      t.boolean :visible, null: false, default: true

      t.timestamps
    end

    # Un état par couple (feature, date clé) — cœur du modèle « états épars ».
    add_index :feature_states, [ :map_feature_id, :key_date_id ], unique: true
  end
end
