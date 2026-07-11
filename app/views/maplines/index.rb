# frozen_string_literal: true

# Tableau de bord auteur : liste des cartes de l'utilisateur.
class Views::Maplines::Index < Views::Base
  def initialize(maplines:)
    @maplines = maplines
  end

  def view_template
    render Views::Layout.new(title: "Mes cartes") do
      div(class: "mb-8 flex items-center justify-between gap-4") do
        h1(class: "text-2xl font-semibold") { "Mes cartes" }
        link_to "Nouvelle carte", new_mapline_path, class: "btn btn-primary"
      end

      if @maplines.any?
        div(class: "flex flex-col gap-3") do
          @maplines.each { |mapline| render_row(mapline) }
        end
      else
        render_empty
      end
    end
  end

  private

  def render_row(mapline)
    div(class: "flex flex-wrap items-center justify-between gap-3 rounded-xl border border-line bg-surface p-5") do
      div(class: "min-w-0") do
        div(class: "flex items-center gap-2") do
          link_to mapline.title, edit_mapline_path(mapline),
            class: "text-lg font-semibold text-ink hover:no-underline hover:underline"
          render Components::StatusBadge.new(status: mapline.status)
        end
        if mapline.description.present?
          p(class: "mt-1 line-clamp-1 text-sm text-muted") { mapline.description }
        end
      end
      div(class: "flex shrink-0 items-center gap-2") do
        unless mapline.draft?
          link_to "Voir", public_mapline_path(mapline.slug), class: "btn btn-ghost text-sm"
        end
        link_to "Modifier", edit_mapline_path(mapline), class: "btn btn-ghost text-sm"
      end
    end
  end

  def render_empty
    div(class: "rounded-xl border border-dashed border-line bg-surface p-10 text-center") do
      p(class: "mb-4 text-muted") { "Vous n'avez pas encore de carte." }
      link_to "Créer ma première carte", new_mapline_path, class: "btn btn-primary"
    end
  end
end
