# frozen_string_literal: true

class Views::Sessions::New < Views::Base
  def view_template
    render Views::Layout.new(title: "Connexion") do
      div(class: "mx-auto max-w-sm rounded-2xl border border-line bg-surface p-8 shadow-lg") do
        h1(class: "mb-6 text-2xl") { "Se connecter" }

        form_with(url: session_path, class: "flex flex-col gap-4") do |form|
          field do
            form.label :email_address, "Adresse e-mail"
            form.email_field :email_address,
              required: true, autofocus: true, autocomplete: "username"
          end

          field do
            form.label :password, "Mot de passe"
            form.password_field :password,
              required: true, autocomplete: "current-password", maxlength: 72
          end

          form.submit "Se connecter", class: "btn btn-primary btn-block"
        end

        p(class: "mt-4 text-sm text-muted") do
          link_to "Mot de passe oublié ?", new_password_path
        end
        p(class: "mt-4 text-sm text-muted") do
          plain "Pas encore de compte ? "
          link_to "Créer un compte", new_registration_path
        end
      end
    end
  end
end
