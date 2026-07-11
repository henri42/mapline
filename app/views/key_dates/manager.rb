# frozen_string_literal: true

# Section « Dates clés » complète, dans le frame Turbo `key_dates_manager`.
# Ajout / suppression rechargent ce frame ; l'édition se fait dans les
# frames imbriqués `key_date_<id>` (voir Views::KeyDates::Row).
class Views::KeyDates::Manager < Views::Base
  def initialize(mapline:, new_key_date: nil)
    @mapline = mapline
    @new_key_date = new_key_date || mapline.key_dates.new
  end

  def view_template
    turbo_frame(id: "key_dates_manager") do
      section(class: "flex flex-col gap-4") do
        header do
          h2(class: "text-xl font-semibold") { "Dates clés" }
          p(class: "text-sm text-muted") do
            "Chaque date clé est un chapitre de la frise. Au moins une est requise pour publier."
          end
        end

        saved_key_dates = @mapline.key_dates.select(&:persisted?)
        if saved_key_dates.any?
          div(class: "flex flex-col gap-2") do
            saved_key_dates.each do |key_date|
              render Views::KeyDates::Row.new(key_date: key_date)
            end
          end
        else
          p(class: "text-sm text-muted") { "Aucune date clé pour l'instant." }
        end

        div(class: "rounded-lg border border-dashed border-line bg-canvas p-4") do
          h3(class: "mb-3 text-sm font-semibold") { "Ajouter une date clé" }
          render Views::KeyDates::Form.new(mapline: @mapline, key_date: @new_key_date)
        end
      end
    end
  end
end
