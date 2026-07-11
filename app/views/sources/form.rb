# frozen_string_literal: true

# Formulaire d'une source (ajout ou édition). Rendu tel quel à l'intérieur
# du frame `sources_manager` (nouvelle source) ou `source_<id>` (édition).
class Views::Sources::Form < Views::Base
  def initialize(mapline:, source:)
    @mapline = mapline
    @source = source
  end

  def view_template
    form_with(model: [ @mapline, @source ], class: "flex flex-col gap-3") do |form|
      if @source.errors.any?
        div(class: "rounded-md bg-error-bg px-3 py-2 text-sm text-error-ink", role: "alert") do
          ul(class: "list-disc pl-5") do
            @source.errors.full_messages.each { |m| li { m } }
          end
        end
      end

      div(class: "grid gap-3 sm:grid-cols-2") do
        field do
          form.label :title, "Titre"
          form.text_field :title, required: true, value: @source.title,
            placeholder: "Ex. Atlas historique de l'Europe"
        end
        field do
          form.label :author, "Auteur (facultatif)"
          form.text_field :author, value: @source.author
        end
      end

      field do
        form.label :url, "Lien (facultatif)"
        form.url_field :url, value: @source.url, placeholder: "https://…"
      end

      div(class: "flex items-center gap-2") do
        form.submit(@source.persisted? ? "Enregistrer" : "Ajouter la source",
          class: button_classes(:primary))
        if @source.persisted?
          Link("Annuler", edit_mapline_path(@mapline),
            variant: :ghost, data: { turbo_frame: "source_#{@source.id}" })
        end
      end
    end
  end
end
