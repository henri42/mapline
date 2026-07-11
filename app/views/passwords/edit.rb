# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  def initialize(token:)
    @token = token
  end

  def view_template
    render Views::Layout.new(title: "Nouveau mot de passe") do
      div(class: "auth-card") do
        h1(class: "auth-card__title") { "Choisir un nouveau mot de passe" }

        form_with(url: password_path(@token), method: :put, class: "form") do |form|
          field do
            form.label :password, "Nouveau mot de passe"
            form.password_field :password,
              required: true, autofocus: true, autocomplete: "new-password", maxlength: 72
          end

          field do
            form.label :password_confirmation, "Confirmer le mot de passe"
            form.password_field :password_confirmation,
              required: true, autocomplete: "new-password", maxlength: 72
          end

          form.submit "Enregistrer", class: "btn btn--primary btn--block"
        end
      end
    end
  end
end
