# frozen_string_literal: true

# Section « Sources » complète, dans le frame Turbo `sources_manager`.
# Ajout / suppression rechargent ce frame ; l'édition se fait dans les
# frames imbriqués `source_<id>` (voir Views::Sources::Row).
class Views::Sources::Manager < Views::Base
  def initialize(mapline:, new_source: nil)
    @mapline = mapline
    @new_source = new_source || mapline.sources.new
  end

  def view_template
    turbo_frame(id: "sources_manager") do
      section(class: "flex flex-col gap-4") do
        header do
          h2(class: "text-xl font-semibold") { "Sources" }
          p(class: "text-sm text-muted") do
            "Au moins une source est requise pour publier la carte."
          end
        end

        saved_sources = @mapline.sources.select(&:persisted?)
        if saved_sources.any?
          div(class: "flex flex-col gap-2") do
            saved_sources.each do |source|
              render Views::Sources::Row.new(source: source)
            end
          end
        else
          p(class: "text-sm text-muted") { "Aucune source pour l'instant." }
        end

        div(class: "rounded-lg border border-dashed border-line bg-canvas p-4") do
          h3(class: "mb-3 text-sm font-semibold") { "Ajouter une source" }
          render Views::Sources::Form.new(mapline: @mapline, source: @new_source)
        end
      end
    end
  end
end
