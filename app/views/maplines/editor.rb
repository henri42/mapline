# frozen_string_literal: true

# Éditeur cartographique (M4) : barre d'outils, carte MapLibre + Terra Draw,
# panneau des éléments et inspecteur de style. Tous les contrôleurs Stimulus
# (editor--*) partagent le store hydraté depuis le payload JSON embarqué.
class Views::Maplines::Editor < Views::Base
  TOOLS = [
    [ "select", "Sélection" ],
    [ "area", "Zone" ],
    [ "line", "Ligne" ],
    [ "arrow", "Flèche" ],
    [ "point", "Point" ],
    [ "label", "Étiquette" ]
  ].freeze

  def initialize(mapline:)
    @mapline = mapline
    @has_key_dates = mapline.key_dates.any?
  end

  def view_template
    section(class: "rounded-2xl border border-line bg-surface p-6") do
      embed_payload

      header(class: "mb-4 flex flex-wrap items-center justify-between gap-3") do
        div do
          h2(class: "text-xl font-semibold") { "Éditeur cartographique" }
          p(class: "text-sm text-muted") { editor_hint }
        end
        span(data: { controller: "editor--autosave" }, class: "text-sm text-muted", role: "status")
      end

      render_toolbar
      render_workspace
    end
  end

  private

  def editor_hint
    if @has_key_dates
      "Choisissez un outil, dessinez sur la carte, puis ajustez le style dans l'inspecteur."
    else
      "Ajoutez au moins une date clé ci-dessus pour commencer à dessiner."
    end
  end

  # Payload hydratant le store JS (features, dates clés, vue initiale).
  def embed_payload
    json = EditorPayload.new(@mapline).as_json.to_json.gsub("</", '<\/')
    script(type: "application/json", id: "editor-payload") { raw(safe(json)) }
  end

  def render_toolbar
    div(
      data: { controller: "editor--toolbar" },
      class: "mb-4 flex flex-wrap items-center gap-2"
    ) do
      TOOLS.each do |tool, label|
        button(
          type: "button",
          data: { editor__toolbar_target: "tool", tool: tool, action: "editor--toolbar#select" },
          class: "btn btn-ghost text-sm disabled:cursor-not-allowed disabled:opacity-40"
        ) { label }
      end
    end
  end

  def render_workspace
    div(class: "grid gap-4 lg:grid-cols-3") do
      render_map
      div(class: "flex flex-col gap-4") do
        render_features_panel
        render_inspector
      end
    end
  end

  def render_map
    div(
      class: "lg:col-span-2",
      data: {
        controller: "editor--map",
        editor__map_center_lng_value: @mapline.center_lng,
        editor__map_center_lat_value: @mapline.center_lat,
        editor__map_zoom_value: @mapline.zoom,
        editor__map_save_url_value: mapline_path(@mapline, format: :json)
      }
    ) do
      div(class: "mb-2 flex items-center justify-end gap-3") do
        span(data: { editor__map_target: "viewStatus" }, class: "text-sm text-muted", role: "status")
        button(type: "button", class: "btn btn-ghost text-sm",
          data: { action: "editor--map#saveInitialView" }) { "Définir la vue initiale" }
      end
      div(data: { editor__map_target: "canvas" },
        class: "h-[520px] w-full overflow-hidden rounded-lg border border-line")
    end
  end

  def render_features_panel
    div(
      data: { controller: "editor--features-panel" },
      class: "rounded-xl border border-line p-4"
    ) do
      h3(class: "mb-3 text-sm font-semibold") { "Éléments" }
      ul(data: { editor__features_panel_target: "list" }, class: "flex flex-col gap-2")
      p(data: { editor__features_panel_target: "empty" }, class: "text-sm text-muted") do
        "Aucun élément. Sélectionnez un outil pour dessiner."
      end
    end
  end

  def render_inspector
    div(
      data: { controller: "editor--inspector" },
      class: "rounded-xl border border-line p-4"
    ) do
      h3(class: "mb-3 text-sm font-semibold") { "Propriétés" }
      div(data: { editor__inspector_target: "body" }, class: "flex flex-col gap-3", hidden: true)
      p(data: { editor__inspector_target: "empty" }, class: "text-sm text-muted") do
        "Sélectionnez un élément pour modifier son nom et son style."
      end
    end
  end
end
