# frozen_string_literal: true

class Views::Passwords::New < Views::Base
  def view_template
    render Views::Layout.new(title: "Mot de passe oublié") do
      div(class: "mx-auto max-w-sm rounded-2xl border border-line bg-surface p-8 shadow-lg") do
        h1(class: "mb-6 text-2xl") { "Mot de passe oublié" }
        p(class: "mt-0 text-muted") do
          "Indiquez votre adresse e-mail : nous vous enverrons un lien de réinitialisation."
        end

        form_with(url: passwords_path, class: "flex flex-col gap-4") do |form|
          field do
            form.label :email_address, "Adresse e-mail"
            form.email_field :email_address,
              required: true, autofocus: true, autocomplete: "username"
          end

          form.submit "Envoyer les instructions", class: "btn btn-primary btn-block"
        end

        p(class: "mt-4 text-sm text-muted") do
          link_to "Retour à la connexion", new_session_path
        end
      end
    end
  end
end
