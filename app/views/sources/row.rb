# frozen_string_literal: true

# Une source dans la liste, encapsulée dans son propre frame Turbo pour
# permettre l'édition en ligne. `editing: true` bascule le frame en formulaire.
class Views::Sources::Row < Views::Base
  def initialize(source:, editing: false)
    @source = source
    @editing = editing
  end

  def view_template
    turbo_frame(id: "source_#{@source.id}") do
      if @editing
        div(class: "rounded-lg border border-primary bg-surface p-4") do
          render Views::Sources::Form.new(mapline: @source.mapline, source: @source)
        end
      else
        display
      end
    end
  end

  private

  def display
    div(class: "flex items-start justify-between gap-3 rounded-lg border border-line bg-surface p-4") do
      div(class: "min-w-0") do
        p(class: "font-semibold text-ink") { @source.title }
        if @source.author.present?
          p(class: "text-sm text-muted") { @source.author }
        end
        if @source.url.present?
          a(href: @source.url, target: "_blank", rel: "noopener",
            class: "text-sm break-all") { @source.url }
        end
      end
      div(class: "flex shrink-0 items-center gap-2") do
        Link("Modifier", edit_mapline_source_path(@source.mapline, @source),
          variant: :ghost, class: "text-sm")
        Button("Supprimer", [ @source.mapline, @source ], method: :delete,
          variant: :danger, class: "text-sm",
          form: { data: { turbo_frame: "sources_manager" }, class: "inline" },
          data: { turbo_confirm: "Supprimer cette source ?" })
      end
    end
  end
end
