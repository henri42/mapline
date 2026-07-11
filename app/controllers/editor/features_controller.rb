class Editor::FeaturesController < Editor::BaseController
  before_action :set_mapline, only: :create
  before_action :set_feature, only: %i[update destroy]

  # Fin d'un tracé Terra Draw : crée la feature et son premier état (à la date
  # clé fournie) de façon transactionnelle.
  def create
    feature = @mapline.map_features.new(feature_attributes)
    feature.feature_states.build(state_attributes) if state_present?

    if feature.save
      render json: feature_json(feature), status: :created
    else
      render json: { errors: nested_errors(feature) }, status: :unprocessable_entity
    end
  end

  # Renommage / restyle / z-index depuis l'inspecteur.
  def update
    if @feature.update(feature_attributes)
      render json: feature_json(@feature)
    else
      render json: { errors: nested_errors(@feature) }, status: :unprocessable_entity
    end
  end

  def destroy
    @feature.destroy
    head :no_content
  end

  private

  def set_mapline
    @mapline = Current.user.maplines.find(params[:mapline_id])
  end

  def set_feature
    @feature = scoped_feature(params[:id])
  end

  def feature_attributes
    raw = params.require(:feature)
    attrs = raw.permit(:name, :feature_type, :z_index).to_h
    attrs[:style] = json_value(raw[:style]) if raw.key?(:style)
    attrs
  end

  def state_present?
    params.require(:feature)[:state].present?
  end

  def state_attributes
    raw = params.require(:feature).require(:state)
    {
      key_date_id: raw[:key_date_id],
      geometry: json_value(raw[:geometry]),
      style_override: json_value(raw[:style_override]),
      visible: raw.key?(:visible) ? raw[:visible] : true
    }
  end

  # Les erreurs d'un état nouvellement construit ne remontent pas sur la feature :
  # on les agrège pour l'affichage client.
  def nested_errors(feature)
    feature.errors.full_messages +
      feature.feature_states.flat_map { |s| s.errors.full_messages }
  end
end
