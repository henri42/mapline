# frozen_string_literal: true

class Views::Sessions::New < Views::Base
  def view_template
    render Views::Layout.new(title: "Connexion") do
      div(class: "auth-card") do
        h1(class: "auth-card__title") { "Se connecter" }

        form_with(url: session_path, class: "form") do |form|
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

          form.submit "Se connecter", class: "btn btn--primary btn--block"
        end

        p(class: "auth-card__aside") do
          link_to "Mot de passe oublié ?", new_password_path
        end
        p(class: "auth-card__aside") do
          plain "Pas encore de compte ? "
          link_to "Créer un compte", new_registration_path
        end
      end
    end
  end
end
