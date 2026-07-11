class MaplinesController < ApplicationController
  before_action :set_mapline, only: %i[edit update destroy change_status]

  # Tableau de bord auteur : la liste de ses cartes.
  def index
    @maplines = Current.user.maplines.order(updated_at: :desc)
    render Views::Maplines::Index.new(maplines: @maplines)
  end

  def new
    render Views::Maplines::New.new(mapline: Current.user.maplines.new)
  end

  def create
    mapline = Current.user.maplines.new(mapline_params)

    if mapline.save
      redirect_to edit_mapline_path(mapline), notice: "Carte créée."
    else
      render Views::Maplines::New.new(mapline: mapline), status: :unprocessable_entity
    end
  end

  def edit
    render Views::Maplines::Edit.new(mapline: @mapline, new_source: @mapline.sources.new)
  end

  def update
    if @mapline.update(mapline_params)
      respond_to do |format|
        format.html { redirect_to edit_mapline_path(@mapline), notice: "Modifications enregistrées." }
        format.json { render json: view_state(@mapline) }
      end
    else
      respond_to do |format|
        format.html do
          render Views::Maplines::Edit.new(mapline: @mapline, new_source: @mapline.sources.new),
            status: :unprocessable_entity
        end
        format.json { render json: { errors: @mapline.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @mapline.destroy
    redirect_to maplines_path, notice: "Carte supprimée."
  end

  # Machine à statuts : draft ⇄ unlisted ⇄ public.
  def change_status
    target = params[:status].to_s

    case target
    when "public", "unlisted"
      if @mapline.publish_as(target)
        redirect_to edit_mapline_path(@mapline),
          notice: target == "public" ? "Carte publiée." : "Carte accessible par lien."
      else
        redirect_to edit_mapline_path(@mapline),
          alert: @mapline.errors.full_messages.to_sentence
      end
    when "draft"
      @mapline.revert_to_draft
      redirect_to edit_mapline_path(@mapline), notice: "Carte repassée en brouillon."
    else
      redirect_to edit_mapline_path(@mapline), alert: "Statut inconnu."
    end
  end

  private

  def set_mapline
    @mapline = Current.user.maplines.find(params[:id])
  end

  def mapline_params
    params.expect(mapline: %i[title description center_lng center_lat zoom])
  end

  def view_state(mapline)
    mapline.slice(:center_lng, :center_lat, :zoom)
  end
end
