# frozen_string_literal: true

class Components::Base < Phlex::HTML
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::FormWith

  # Rend le kit disponible : `Button(...)`, `Link(...)`, `StatusBadge(...)`
  # s'appellent directement, sans `render` ni nom de classe complet.
  include Components

  # `<turbo-frame>` : Phlex convertit l'underscore en tiret.
  register_element :turbo_frame

  # Variantes partagées par Button et Link (liens stylés en bouton).
  BUTTON_VARIANTS = {
    primary: "btn btn-primary",
    ghost: "btn btn-ghost",
    danger: "btn btn-ghost text-error-ink"
  }.freeze

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end

  # Enveloppe standard d'un champ de formulaire (label + input).
  def field(&block)
    div(class: "field", &block)
  end

  # Classe CSS d'un bouton (ou lien-bouton) selon sa variante.
  def button_classes(variant, block: false, extra: nil)
    [ BUTTON_VARIANTS.fetch(variant), ("btn-block" if block), extra ].compact.join(" ")
  end
end
