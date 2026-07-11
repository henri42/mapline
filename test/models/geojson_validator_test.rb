require "test_helper"

class GeojsonValidatorTest < ActiveSupport::TestCase
  # Modèle jetable pour exercer le validateur isolément.
  class Geom
    include ActiveModel::Validations
    attr_accessor :geometry
    validates :geometry, geojson: true
  end

  def geom(value)
    g = Geom.new
    g.geometry = value
    g
  end

  test "accepte un Point aux coordonnées valides" do
    assert geom("type" => "Point", "coordinates" => [ 2.35, 48.85 ]).valid?
  end

  test "accepte un Polygon" do
    ring = [ [ 2.0, 48.0 ], [ 3.0, 48.0 ], [ 3.0, 49.0 ], [ 2.0, 48.0 ] ]
    assert geom("type" => "Polygon", "coordinates" => [ ring ]).valid?
  end

  test "rejette un type non pris en charge" do
    assert_not geom("type" => "GeometryCollection", "coordinates" => []).valid?
  end

  test "rejette une longitude hors bornes" do
    assert_not geom("type" => "Point", "coordinates" => [ 200.0, 10.0 ]).valid?
  end

  test "rejette une latitude hors bornes" do
    assert_not geom("type" => "Point", "coordinates" => [ 10.0, 120.0 ]).valid?
  end

  test "rejette une géométrie vide ou non-hash" do
    assert_not geom(nil).valid?
    assert_not geom("pas un hash").valid?
  end

  test "rejette une géométrie trop volumineuse" do
    huge = Array.new(80_000) { [ 1.0, 1.0 ] }
    assert_not geom("type" => "LineString", "coordinates" => huge).valid?
  end
end
