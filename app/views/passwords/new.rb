# frozen_string_literal: true

class Views::Passwords::New < Views::Base
  def view_template
    render Views::Layout.new(title: "Mot de passe oublié") do
      div(class: "auth-card") do
        h1(class: "auth-card__title") { "Mot de passe oublié" }
        p(class: "auth-card__intro") do
          "Indiquez votre adresse e-mail : nous vous enverrons un lien de réinitialisation."
        end

        form_with(url: passwords_path, class: "form") do |form|
          field do
            form.label :email_address, "Adresse e-mail"
            form.email_field :email_address,
              required: true, autofocus: true, autocomplete: "username"
          end

          form.submit "Envoyer les instructions", class: "btn btn--primary btn--block"
        end

        p(class: "auth-card__aside") do
          link_to "Retour à la connexion", new_session_path
        end
      end
    end
  end
end
