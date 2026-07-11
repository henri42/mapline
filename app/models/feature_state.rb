# État d'une feature à une date clé — cœur du versionnement (« états épars +
# report en avant »). Un état existe pour un couple (feature, date clé)
# uniquement quand quelque chose change ; la résolution carry-forward (M5)
# reporte le dernier état connu vers l'avant.
class FeatureState < ApplicationRecord
  belongs_to :map_feature
  belongs_to :key_date

  validates :geometry, geojson: true
  validate :geometry_type_matches_feature
  validates :map_feature_id, uniqueness: { scope: :key_date_id,
    message: "un état existe déjà pour cette feature à cette date clé" }
  validate :key_date_belongs_to_same_mapline

  # Style effectif de l'état : style du type + style de la feature + surcharge.
  def resolved_style
    map_feature.resolved_style.merge(style_override || {})
  end

  private

  def geometry_type_matches_feature
    return if geometry.blank? || map_feature.nil?

    type = geometry.stringify_keys["type"]
    return if map_feature.allowed_geometry_types.include?(type)

    errors.add(:geometry, "type #{type.inspect} incompatible avec un élément #{map_feature.feature_type}")
  end

  # Une date clé d'une autre carte n'a pas de sens pour cet état.
  def key_date_belongs_to_same_mapline
    return if map_feature.nil? || key_date.nil?

    unless key_date.mapline_id == map_feature.mapline_id
      errors.add(:key_date, "n'appartient pas à la même carte")
    end
  end
end
