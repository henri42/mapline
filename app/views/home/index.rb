# frozen_string_literal: true

class Views::Home::Index < Views::Base
  def view_template
    render Views::Layout.new(title: "Accueil") do
      section(class: "py-12 text-center") do
        h1(class: "mb-4 font-serif text-[clamp(2rem,5vw,3rem)] leading-[1.1]") do
          "Des cartes qui racontent l'Histoire"
        end
        p(class: "mx-auto mb-8 max-w-2xl text-lg text-muted") do
          plain "Mapline vous permet de composer des cartes historiques et "
          plain "géopolitiques qui évoluent au fil d'une frise chronologique."
        end
        div(class: "flex flex-wrap justify-center gap-3") do
          if Current.user
            link_to("Accéder à mon espace", root_path, class: "btn btn-primary")
          else
            link_to("Créer un compte", new_registration_path, class: "btn btn-primary")
            link_to("Se connecter", new_session_path, class: "btn btn-ghost")
          end
        end
      end
    end
  end
end
