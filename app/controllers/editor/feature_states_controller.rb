class Editor::FeatureStatesController < Editor::BaseController
  before_action :set_feature

  # Upsert idempotent de l'état (feature, date clé) : autosave de la géométrie
  # après édition, ou création explicite d'un état.
  def upsert
    state = @feature.feature_states.find_or_initialize_by(key_date_id: params[:key_date_id])
    state.assign_attributes(state_attributes)

    if state.save
      render json: state_json(state)
    else
      render json: { errors: state.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Supprime l'état à cette date clé (revenir à l'héritage — pertinent dès M5).
  def destroy
    @feature.feature_states.find_by(key_date_id: params[:key_date_id])&.destroy
    head :no_content
  end

  private

  def set_feature
    @feature = scoped_feature(params[:feature_id])
  end

  def state_attributes
    raw = params.require(:state)
    attrs = {}
    attrs[:geometry] = json_value(raw[:geometry]) if raw.key?(:geometry)
    attrs[:style_override] = json_value(raw[:style_override]) if raw.key?(:style_override)
    attrs[:visible] = raw[:visible] if raw.key?(:visible)
    attrs
  end
end
