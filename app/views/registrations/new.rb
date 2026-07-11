# frozen_string_literal: true

class Views::Registrations::New < Views::Base
  def initialize(user:)
    @user = user
  end

  def view_template
    render Views::Layout.new(title: "Créer un compte") do
      div(class: "mx-auto max-w-sm rounded-2xl border border-line bg-surface p-8 shadow-lg") do
        h1(class: "mb-6 text-2xl") { "Créer un compte" }

        render_errors

        form_with(url: registration_path, class: "flex flex-col gap-4") do |form|
          field do
            form.label :display_name, "Nom affiché"
            form.text_field :display_name,
              required: true, autofocus: true, autocomplete: "name",
              value: @user.display_name
          end

          field do
            form.label :email_address, "Adresse e-mail"
            form.email_field :email_address,
              required: true, autocomplete: "email",
              value: @user.email_address
          end

          field do
            form.label :password, "Mot de passe"
            form.password_field :password,
              required: true, autocomplete: "new-password", maxlength: 72
          end

          field do
            form.label :password_confirmation, "Confirmer le mot de passe"
            form.password_field :password_confirmation,
              required: true, autocomplete: "new-password", maxlength: 72
          end

          form.submit "Créer mon compte", class: button_classes(:primary, block: true)
        end

        p(class: "mt-4 text-sm text-muted") do
          plain "Déjà inscrit ? "
          Link("Se connecter", new_session_path)
        end
      end
    end
  end

  private

  def render_errors
    return if @user.errors.empty?

    div(class: "mb-6 rounded-md bg-error-bg px-4 py-3 text-error-ink", role: "alert") do
      p(class: "mb-2 font-semibold") { "Impossible de créer le compte :" }
      ul(class: "list-disc pl-6") do
        @user.errors.full_messages.each do |message|
          li { message }
        end
      end
    end
  end
end
