# frozen_string_literal: true

# Une date clé dans la liste, encapsulée dans son propre frame Turbo pour
# permettre l'édition en ligne. `editing: true` bascule le frame en formulaire.
class Views::KeyDates::Row < Views::Base
  def initialize(key_date:, editing: false)
    @key_date = key_date
    @editing = editing
  end

  def view_template
    turbo_frame(id: "key_date_#{@key_date.id}") do
      if @editing
        div(class: "rounded-lg border border-primary bg-surface p-4") do
          render Views::KeyDates::Form.new(mapline: @key_date.mapline, key_date: @key_date)
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
        p(class: "font-semibold text-ink") { @key_date.display_date }
        if @key_date.title.present?
          p(class: "text-sm text-muted") { @key_date.title }
        end
        if @key_date.description.present?
          p(class: "mt-1 text-sm text-muted") { @key_date.description }
        end
      end
      div(class: "flex shrink-0 items-center gap-2") do
        Link("Modifier", edit_mapline_key_date_path(@key_date.mapline, @key_date),
          variant: :ghost, class: "text-sm")
        Button("Supprimer", [ @key_date.mapline, @key_date ], method: :delete,
          variant: :danger, class: "text-sm",
          form: { data: { turbo_frame: "key_dates_manager" }, class: "inline" },
          data: { turbo_confirm: "Supprimer cette date clé ?" })
      end
    end
  end
end
