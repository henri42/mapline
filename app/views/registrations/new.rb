# frozen_string_literal: true

class Views::Registrations::New < Views::Base
  def initialize(user:)
    @user = user
  end

  def view_template
    render Views::Layout.new(title: "Créer un compte") do
      div(class: "auth-card") do
        h1(class: "auth-card__title") { "Créer un compte" }

        render_errors

        form_with(url: registration_path, class: "form") do |form|
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

          form.submit "Créer mon compte", class: "btn btn--primary btn--block"
        end

        p(class: "auth-card__aside") do
          plain "Déjà inscrit ? "
          link_to "Se connecter", new_session_path
        end
      end
    end
  end

  private

  def render_errors
    return if @user.errors.empty?

    div(class: "form-errors", role: "alert") do
      p(class: "form-errors__title") { "Impossible de créer le compte :" }
      ul do
        @user.errors.full_messages.each do |message|
          li { message }
        end
      end
    end
  end
end
