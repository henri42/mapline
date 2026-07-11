# frozen_string_literal: true

# Formulaire d'une date clé (ajout ou édition). Rendu tel quel à l'intérieur
# du frame `key_dates_manager` (nouvelle date) ou `key_date_<id>` (édition).
# Saisie : année positive + ère (av./ap. J.-C.), mois et jour facultatifs.
class Views::KeyDates::Form < Views::Base
  # Classe des `<select>` (le `.field > input` de la CSS ne cible pas les selects).
  SELECT_CLASS = "w-full rounded-md border border-line bg-surface px-3 py-2.5 text-ink"

  def initialize(mapline:, key_date:)
    @mapline = mapline
    @key_date = key_date
  end

  def view_template
    form_with(model: [ @mapline, @key_date ], class: "flex flex-col gap-3") do |form|
      if @key_date.errors.any?
        div(class: "rounded-md bg-error-bg px-3 py-2 text-sm text-error-ink", role: "alert") do
          ul(class: "list-disc pl-5") do
            @key_date.errors.full_messages.each { |m| li { m } }
          end
        end
      end

      div(class: "grid gap-3 sm:grid-cols-4") do
        field do
          form.label :year_input, "Année"
          form.number_field :year_input, value: @key_date.year_input,
            min: 1, required: true, placeholder: "1815"
        end
        field do
          form.label :era, "Ère"
          form.select :era, [ [ "ap. J.-C.", "ce" ], [ "av. J.-C.", "bc" ] ],
            { selected: @key_date.era }, class: SELECT_CLASS
        end
        field do
          form.label :month, "Mois (facultatif)"
          form.select :month, mois_options,
            { include_blank: "—", selected: @key_date.month }, class: SELECT_CLASS
        end
        field do
          form.label :day, "Jour (facultatif)"
          form.number_field :day, value: @key_date.day, min: 1, max: 31
        end
      end

      div(class: "grid gap-3 sm:grid-cols-2") do
        field do
          form.label :title, "Titre (facultatif)"
          form.text_field :title, value: @key_date.title,
            placeholder: "Ex. Congrès de Vienne"
        end
        field do
          form.label :label, "Libellé de date (facultatif)"
          form.text_field :label, value: @key_date.label, placeholder: "Ex. vers 800"
        end
      end

      field do
        form.label :description, "Description (facultatif)"
        form.text_area :description, rows: 3, value: @key_date.description,
          class: "w-full rounded-md border border-line bg-surface px-3 py-2.5 text-ink"
      end

      div(class: "flex items-center gap-2") do
        form.submit(@key_date.persisted? ? "Enregistrer" : "Ajouter la date clé",
          class: button_classes(:primary))
        if @key_date.persisted?
          Link("Annuler", edit_mapline_path(@mapline),
            variant: :ghost, data: { turbo_frame: "key_date_#{@key_date.id}" })
        end
      end
    end
  end

  private

  def mois_options
    KeyDate::MOIS.each_with_index.map { |nom, i| [ nom.capitalize, i + 1 ] }
  end
end
