# Sérialise une carte pour l'éditeur : payload embarqué dans la page (script
# JSON, hydrate le store côté client) et réponses des endpoints Editor::.
# Un seul endroit pour la forme du JSON éditeur, partagé vue ↔ contrôleurs.
class EditorPayload
  include Rails.application.routes.url_helpers

  # JSON d'une feature seule (réponse create/update).
  def self.feature(feature)
    {
      id: feature.id,
      featureType: feature.feature_type,
      name: feature.name,
      zIndex: feature.z_index,
      # Style résolu (défauts du type fusionnés) : le client rend directement.
      style: feature.resolved_style,
      states: feature.feature_states.each_with_object({}) do |state, acc|
        acc[state.key_date_id] = state_body(state)
      end
    }
  end

  def self.state_body(state)
    { geometry: state.geometry, styleOverride: state.style_override, visible: state.visible }
  end

  def initialize(mapline)
    @mapline = mapline
  end

  def as_json(*)
    {
      mapline: {
        id: @mapline.id,
        centerLng: @mapline.center_lng,
        centerLat: @mapline.center_lat,
        zoom: @mapline.zoom,
        updateUrl: mapline_path(@mapline, format: :json)
      },
      keyDates: @mapline.key_dates.map do |kd|
        { id: kd.id, sortKey: kd.sort_key, label: kd.display_date, title: kd.title }
      end,
      features: @mapline.map_features.includes(feature_states: :key_date).map { |f| self.class.feature(f) }
    }
  end
end
