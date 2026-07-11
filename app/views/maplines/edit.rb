# frozen_string_literal: true

# Page de gestion d'une carte : réglages, statut de publication et sources.
# (L'éditeur cartographique arrive aux jalons suivants.)
class Views::Maplines::Edit < Views::Base
  def initialize(mapline:, new_source: nil)
    @mapline = mapline
    @new_source = new_source
  end

  def view_template
    render Views::Layout.new(title: @mapline.title) do
      div(class: "mb-6 flex flex-wrap items-center justify-between gap-3") do
        div(class: "flex items-center gap-3") do
          link_to "← Mes cartes", maplines_path, class: "text-sm text-muted"
        end
        unless @mapline.draft?
          link_to "Voir la page publique", public_mapline_path(@mapline.slug),
            class: "btn btn-ghost text-sm"
        end
      end

      div(class: "flex items-center gap-3") do
        h1(class: "text-2xl font-semibold") { @mapline.title }
        render Components::StatusBadge.new(status: @mapline.status)
      end

      div(class: "mt-8 flex flex-col gap-8") do
        render_settings
        render_publish
        render Views::Sources::Manager.new(mapline: @mapline, new_source: @new_source)
        render_map_placeholder
      end
    end
  end

  private

  def render_settings
    section(class: "rounded-2xl border border-line bg-surface p-6") do
      h2(class: "mb-4 text-xl font-semibold") { "Réglages" }

      if @mapline.errors.any?
        div(class: "mb-4 rounded-md bg-error-bg px-4 py-3 text-error-ink", role: "alert") do
          ul(class: "list-disc pl-6") do
            @mapline.errors.full_messages.each { |m| li { m } }
          end
        end
      end

      form_with(model: @mapline, method: :patch, class: "flex flex-col gap-4") do |form|
        field do
          form.label :title, "Titre"
          form.text_field :title, required: true, value: @mapline.title
        end
        field do
          form.label :description, "Description"
          form.text_area :description, rows: 4, value: @mapline.description,
            class: "w-full rounded-md border border-line bg-surface px-3 py-2.5 text-ink"
        end
        div { form.submit "Enregistrer", class: "btn btn-primary" }
      end
    end
  end

  def render_publish
    section(class: "rounded-2xl border border-line bg-surface p-6") do
      h2(class: "mb-1 text-xl font-semibold") { "Publication" }
      p(class: "mb-4 text-sm text-muted") { publication_hint }

      div(class: "flex flex-wrap gap-2") do
        unless @mapline.public?
          button_to "Publier", change_status_mapline_path(@mapline, status: "public"),
            method: :patch, class: "btn btn-primary"
        end
        unless @mapline.unlisted?
          button_to "Rendre accessible par lien",
            change_status_mapline_path(@mapline, status: "unlisted"),
            method: :patch, class: "btn btn-ghost"
        end
        unless @mapline.draft?
          button_to "Repasser en brouillon",
            change_status_mapline_path(@mapline, status: "draft"),
            method: :patch, class: "btn btn-ghost"
        end
      end
    end
  end

  def publication_hint
    case @mapline.status
    when "public"    then "Cette carte est publique : elle apparaît sur votre profil."
    when "unlisted"  then "Cette carte est accessible uniquement via son lien."
    else "Cette carte est un brouillon, visible de vous seul."
    end
  end

  def render_map_placeholder
    section(class: "rounded-2xl border border-dashed border-line bg-canvas p-6 text-center text-muted") do
      p { "L'éditeur cartographique et la frise chronologique arriveront prochainement." }
    end
  end
end
