# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  def initialize(token:)
    @token = token
  end

  def view_template
    render Views::Layout.new(title: "Nouveau mot de passe") do
      div(class: "mx-auto max-w-sm rounded-2xl border border-line bg-surface p-8 shadow-lg") do
        h1(class: "mb-6 text-2xl") { "Choisir un nouveau mot de passe" }

        form_with(url: password_path(@token), method: :put, class: "flex flex-col gap-4") do |form|
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

          form.submit "Enregistrer", class: button_classes(:primary, block: true)
        end
      end
    end
  end
end
