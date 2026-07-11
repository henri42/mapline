# Base des endpoints JSON de l'éditeur (namespace Editor::). Répond en JSON,
# charge les enregistrements via Current.user pour un contrôle d'accès strict
# (l'accès à la carte d'un autre auteur 404), et partage la sérialisation.
class Editor::BaseController < ApplicationController
  private

  # Une feature de l'utilisateur courant (sinon RecordNotFound → 404).
  def scoped_feature(id)
    MapFeature.where(mapline: Current.user.maplines).find(id)
  end

  # Les colonnes JSON arrivent en ActionController::Parameters (hashes) ou en
  # tableaux bruts (coordonnées) : on les convertit en structure Ruby simple.
  def json_value(value)
    value.is_a?(ActionController::Parameters) ? value.to_unsafe_h : value
  end

  def feature_json(feature)
    EditorPayload.feature(feature)
  end

  def state_json(state)
    { keyDateId: state.key_date_id, **EditorPayload.state_body(state) }
  end
end
