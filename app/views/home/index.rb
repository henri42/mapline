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
            Link("Accéder à mes cartes", maplines_path, variant: :primary)
          else
            Link("Créer un compte", new_registration_path, variant: :primary)
            Link("Se connecter", new_session_path, variant: :ghost)
          end
        end
      end
    end
  end
end
