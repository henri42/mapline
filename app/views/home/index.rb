# frozen_string_literal: true

class Views::Home::Index < Views::Base
  def view_template
    render Views::Layout.new(title: "Accueil") do
      section(class: "hero") do
        h1(class: "hero__title") { "Des cartes qui racontent l'Histoire" }
        p(class: "hero__lead") do
          plain "Mapline vous permet de composer des cartes historiques et "
          plain "géopolitiques qui évoluent au fil d'une frise chronologique."
        end
        div(class: "hero__actions") do
          if Current.user
            link_to("Accéder à mon espace", root_path, class: "btn btn--primary")
          else
            link_to("Créer un compte", new_registration_path, class: "btn btn--primary")
            link_to("Se connecter", new_session_path, class: "btn btn--ghost")
          end
        end
      end
    end
  end
end
