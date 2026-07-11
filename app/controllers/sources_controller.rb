class SourcesController < ApplicationController
  before_action :set_mapline
  before_action :set_source, only: %i[edit update destroy]

  # Ajout : recharge le frame `sources_manager` (liste + formulaire vide).
  def create
    source = @mapline.sources.new(source_params)

    if source.save
      redirect_to edit_mapline_path(@mapline)
    else
      render Views::Sources::Manager.new(mapline: @mapline, new_source: source),
        status: :unprocessable_entity
    end
  end

  # Édition en ligne : bascule le frame `source_<id>` en formulaire.
  def edit
    render Views::Sources::Row.new(source: @source, editing: true)
  end

  def update
    if @source.update(source_params)
      redirect_to edit_mapline_path(@mapline)
    else
      render Views::Sources::Row.new(source: @source, editing: true),
        status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy
    redirect_to edit_mapline_path(@mapline)
  end

  private

  def set_mapline
    @mapline = Current.user.maplines.find(params[:mapline_id])
  end

  def set_source
    @source = @mapline.sources.find(params[:id])
  end

  def source_params
    params.expect(source: %i[title url author])
  end
end
