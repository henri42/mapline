class KeyDatesController < ApplicationController
  before_action :set_mapline
  before_action :set_key_date, only: %i[edit update destroy]

  # Ajout : recharge le frame `key_dates_manager` (liste + formulaire vide).
  def create
    key_date = @mapline.key_dates.new(key_date_params)

    if key_date.save
      redirect_to edit_mapline_path(@mapline)
    else
      render Views::KeyDates::Manager.new(mapline: @mapline, new_key_date: key_date),
        status: :unprocessable_entity
    end
  end

  # Édition en ligne : bascule le frame `key_date_<id>` en formulaire.
  def edit
    render Views::KeyDates::Row.new(key_date: @key_date, editing: true)
  end

  def update
    if @key_date.update(key_date_params)
      redirect_to edit_mapline_path(@mapline)
    else
      render Views::KeyDates::Row.new(key_date: @key_date, editing: true),
        status: :unprocessable_entity
    end
  end

  def destroy
    @key_date.destroy
    redirect_to edit_mapline_path(@mapline)
  end

  private

  def set_mapline
    @mapline = Current.user.maplines.find(params[:mapline_id])
  end

  def set_key_date
    @key_date = @mapline.key_dates.find(params[:id])
  end

  def key_date_params
    params.expect(key_date: %i[year_input era month day label title description])
  end
end
