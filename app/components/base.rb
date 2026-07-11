# frozen_string_literal: true

class Components::Base < Phlex::HTML
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::FormWith

  # `<turbo-frame>` : Phlex convertit l'underscore en tiret.
  register_element :turbo_frame

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
end
