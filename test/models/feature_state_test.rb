require "test_helper"

class FeatureStateTest < ActiveSupport::TestCase
  setup do
    @mapline = maplines(:alice_public)
    @key_date = key_dates(:vienne)
  end

  def area
    @mapline.map_features.create!(feature_type: "area")
  end

  def polygon
    { "type" => "Polygon", "coordinates" => [ [ [ 2.0, 48.0 ], [ 3.0, 48.0 ], [ 3.0, 49.0 ], [ 2.0, 48.0 ] ] ] }
  end

  test "un état valide pour une area en Polygon" do
    state = area.feature_states.new(key_date: @key_date, geometry: polygon)

    assert state.valid?
  end

  test "rejette une géométrie incompatible avec le type de feature" do
    state = area.feature_states.new(key_date: @key_date,
      geometry: { "type" => "Point", "coordinates" => [ 2.0, 48.0 ] })

    assert_not state.valid?
    assert_includes state.errors.full_messages.join, "incompatible"
  end

  test "un seul état par couple (feature, date clé)" do
    feature = area
    feature.feature_states.create!(key_date: @key_date, geometry: polygon)
    doublon = feature.feature_states.new(key_date: @key_date, geometry: polygon)

    assert_not doublon.valid?
  end

  test "rejette une date clé d'une autre carte" do
    autre_date = maplines(:alice_draft).key_dates.create!(year_input: 1800, era: "ce")
    state = area.feature_states.new(key_date: autre_date, geometry: polygon)

    assert_not state.valid?
    assert_includes state.errors.full_messages.join, "même carte"
  end

  test "resolved_style superpose la surcharge d'état sur le style de la feature" do
    feature = @mapline.map_features.create!(feature_type: "area", style: { "fill" => "#111111" })
    state = feature.feature_states.new(key_date: @key_date, geometry: polygon,
      style_override: { "fillOpacity" => 0.9 })

    assert_equal "#111111", state.resolved_style["fill"]      # de la feature
    assert_equal 0.9, state.resolved_style["fillOpacity"]     # de la surcharge
  end
end
