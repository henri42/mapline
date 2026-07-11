# Validation serveur légère des géométries GeoJSON (pas de PostGIS/RGeo en v1 :
# les géométries sont des blobs que le serveur stocke et resert, tout le travail
# spatial est côté client). On vérifie seulement :
#   - un type de géométrie autorisé ;
#   - des coordonnées bornées ([-180,180] en longitude, [-90,90] en latitude) ;
#   - une taille sérialisée raisonnable (~500 Ko).
#
#   validates :geometry, geojson: true
#   validates :geometry, geojson: { types: %w[Point] }
class GeojsonValidator < ActiveModel::EachValidator
  ALLOWED_TYPES = %w[Point LineString Polygon MultiPolygon].freeze
  MAX_BYTESIZE = 500.kilobytes

  def validate_each(record, attribute, value)
    return record.errors.add(attribute, :blank) if value.blank?
    return record.errors.add(attribute, :invalid) unless value.is_a?(Hash)

    geo = value.stringify_keys
    types = options.fetch(:types, ALLOWED_TYPES)

    unless types.include?(geo["type"])
      return record.errors.add(attribute, :invalid_geojson_type,
        message: "type de géométrie non pris en charge")
    end

    if value.to_json.bytesize > MAX_BYTESIZE
      return record.errors.add(attribute, :geojson_too_large,
        message: "géométrie trop volumineuse")
    end

    unless coordinates_within_bounds?(geo["coordinates"])
      record.errors.add(attribute, :invalid_coordinates,
        message: "coordonnées hors limites")
    end
  end

  private

  # Parcourt récursivement l'arbre de coordonnées ; une « position » est un
  # tableau dont le premier élément est un nombre ([lng, lat, alt?]).
  def coordinates_within_bounds?(coordinates)
    return false unless coordinates.is_a?(Array) && coordinates.any?

    if position?(coordinates)
      lng, lat = coordinates
      lng.is_a?(Numeric) && lat.is_a?(Numeric) &&
        lng.between?(-180, 180) && lat.between?(-90, 90)
    else
      coordinates.all? { |child| coordinates_within_bounds?(child) }
    end
  end

  def position?(array)
    array.first.is_a?(Numeric)
  end
end
