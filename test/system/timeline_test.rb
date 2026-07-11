require "application_system_test_case"

class TimelineTest < ApplicationSystemTestCase
  # La frise est le composant partagé éditeur/lecteur : on vérifie ici la
  # navigation côté lecteur (boutons préc./suiv.), qui met à jour le panneau.
  test "la frise navigue entre les dates clés sur la page publique" do
    mapline = maplines(:alice_public)
    visit public_mapline_path(mapline.slug)

    within "[data-controller='timeline']" do
      assert_text "Congrès de Vienne"

      find("[data-action='timeline#next']").click
      assert_text "Bataille de Waterloo"

      find("[data-action='timeline#previous']").click
      assert_text "Congrès de Vienne"
    end
  end
end
