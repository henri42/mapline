# Élément cartographique — identité stable dans le temps (« Royaume de France »).
# Sa forme peut changer à chaque date clé : voir FeatureState (versionnement).
class MapFeature < ApplicationRecord
  belongs_to :mapline
  has_many :feature_states, -> { includes(:key_date).order("key_dates.sort_key") },
    dependent: :destroy, inverse_of: :map_feature

  # Types d'éléments. Chacun impose une famille de géométrie GeoJSON :
  #   area          → Polygon / MultiPolygon
  #   line / arrow  → LineString
  #   point / label → Point
  FEATURE_TYPES = %w[area line arrow point label].freeze

  # Géométrie GeoJSON autorisée par type (contrôle croisé dans FeatureState).
  GEOMETRY_TYPES = {
    "area" => %w[Polygon MultiPolygon],
    "line" => %w[LineString],
    "arrow" => %w[LineString],
    "point" => %w[Point],
    "label" => %w[Point]
  }.freeze

  # Style par défaut par type — l'inspecteur fusionne ses réglages par-dessus.
  DEFAULT_STYLES = {
    "area" => { "fill" => "#3b82f6", "fillOpacity" => 0.35, "stroke" => "#1d4ed8", "strokeWidth" => 2 },
    "line" => { "stroke" => "#1d4ed8", "strokeWidth" => 3 },
    "arrow" => { "stroke" => "#b91c1c", "strokeWidth" => 3 },
    "point" => { "fill" => "#1d4ed8", "radius" => 6, "stroke" => "#ffffff", "strokeWidth" => 2 },
    "label" => { "textColor" => "#1c1b1a", "textSize" => 14 }
  }.freeze

  enum :feature_type, FEATURE_TYPES.index_by(&:itself), validate: true

  validates :name, length: { maximum: 120 }

  # Géométries autorisées pour ce type (utilisé par FeatureState).
  def allowed_geometry_types
    GEOMETRY_TYPES.fetch(feature_type, [])
  end

  # Style effectif = défauts du type fusionnés avec le style enregistré.
  def resolved_style
    DEFAULT_STYLES.fetch(feature_type, {}).merge(style || {})
  end
end
