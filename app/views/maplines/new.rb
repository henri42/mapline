# frozen_string_literal: true

class Views::Maplines::New < Views::Base
  def initialize(mapline:)
    @mapline = mapline
  end

  def view_template
    render Views::Layout.new(title: "Nouvelle carte") do
      div(class: "mx-auto max-w-xl") do
        h1(class: "mb-6 text-2xl font-semibold") { "Nouvelle carte" }

        div(class: "rounded-2xl border border-line bg-surface p-8") do
          render_errors

          form_with(model: @mapline, class: "flex flex-col gap-4") do |form|
            field do
              form.label :title, "Titre"
              form.text_field :title, required: true, autofocus: true,
                value: @mapline.title, placeholder: "Ex. L'Europe en 1815"
            end
            field do
              form.label :description, "Description (facultatif)"
              form.text_area :description, rows: 4, value: @mapline.description,
                class: "w-full rounded-md border border-line bg-surface px-3 py-2.5 text-ink"
            end
            div(class: "flex items-center gap-2") do
              form.submit "Créer la carte", class: "btn btn-primary"
              link_to "Annuler", maplines_path, class: "btn btn-ghost"
            end
          end
        end
      end
    end
  end

  private

  def render_errors
    return if @mapline.errors.empty?

    div(class: "mb-6 rounded-md bg-error-bg px-4 py-3 text-error-ink", role: "alert") do
      ul(class: "list-disc pl-6") do
        @mapline.errors.full_messages.each { |m| li { m } }
      end
    end
  end
end
