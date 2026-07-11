# frozen_string_literal: true

# Document HTML complet partagé par toutes les pages serveur (Phlex).
# Les tags Vite injectent le client HMR (dev) et l'entrypoint JS/CSS.
class Views::Layout < Components::Base
  extend Phlex::Rails::HelperMacros

  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::CSPMetaTag
  include Phlex::Rails::Helpers::Flash
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo

  register_output_helper :vite_client_tag
  register_output_helper :vite_javascript_tag

  def initialize(title: nil)
    @title = title
  end

  def view_template(&block)
    doctype
    html(lang: "fr") do
      head do
        title { [@title, "Mapline"].compact.join(" · ") }
        meta(name: "viewport", content: "width=device-width,initial-scale=1")
        meta(name: "apple-mobile-web-app-capable", content: "yes")
        csrf_meta_tags
        csp_meta_tag
        link(rel: "icon", href: "/icon.svg", type: "image/svg+xml")
        vite_client_tag
        vite_javascript_tag("application")
      end
      body(class: "min-h-screen bg-canvas font-sans leading-relaxed text-ink antialiased") do
        render_header
        main(class: "mx-auto w-full max-w-5xl px-4 py-8") do
          render_flash
          yield
        end
      end
    end
  end

  private

  def render_header
    header(class: "border-b border-line bg-surface") do
      div(class: "mx-auto flex w-full max-w-5xl items-center justify-between gap-4 px-4 py-3") do
        link_to("Mapline", root_path, class: "text-xl font-bold text-ink hover:no-underline")
        nav(class: "flex items-center gap-3") do
          if Current.user
            span(class: "text-sm text-muted") { Current.user.display_name }
            button_to("Se déconnecter", session_path, method: :delete, class: "btn btn-ghost")
          else
            link_to("Se connecter", new_session_path, class: "btn btn-ghost")
            link_to("Créer un compte", new_registration_path, class: "btn btn-primary")
          end
        end
      end
    end
  end

  def render_flash
    flash.each do |type, message|
      next if message.blank?

      classes = if type.to_s == "alert"
        "bg-error-bg text-error-ink"
      else
        "bg-notice-bg text-notice-ink"
      end
      div(class: "mb-4 rounded-md px-4 py-3 text-sm #{classes}", role: "status") { message }
    end
  end
end
