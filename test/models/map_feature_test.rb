require "test_helper"

class MapFeatureTest < ActiveSupport::TestCase
  setup { @mapline = maplines(:alice_public) }

  test "exige un type de feature valide" do
    feature = @mapline.map_features.new(feature_type: "blob")

    assert_not feature.valid?
    assert_includes feature.errors.attribute_names, :feature_type
    assert @mapline.map_features.new(feature_type: "area").valid?
  end

  test "resolved_style fusionne les défauts du type avec le style enregistré" do
    feature = @mapline.map_features.new(feature_type: "area", style: { "fill" => "#000000" })

    assert_equal "#000000", feature.resolved_style["fill"]
    assert_equal 2, feature.resolved_style["strokeWidth"] # défaut conservé
  end

  test "allowed_geometry_types dépend du type" do
    assert_equal %w[Polygon MultiPolygon], @mapline.map_features.new(feature_type: "area").allowed_geometry_types
    assert_equal %w[Point], @mapline.map_features.new(feature_type: "label").allowed_geometry_types
  end

  test "supprimer une feature supprime ses états" do
    feature = @mapline.map_features.create!(feature_type: "point")
    feature.feature_states.create!(key_date: key_dates(:vienne),
      geometry: { "type" => "Point", "coordinates" => [ 2.0, 48.0 ] })

    assert_difference -> { FeatureState.count }, -1 do
      feature.destroy
    end
  end
end
