require "application_system_test_case"

class EditorTest < ApplicationSystemTestCase
  setup do
    @mapline = maplines(:alice_public) # possède déjà deux dates clés
    sign_in_as users(:one)
  end

  test "dessiner un point le persiste, le rend et permet de le supprimer" do
    visit edit_mapline_path(@mapline)

    # Attendre le chargement de la carte (tuiles + Terra Draw prêts).
    assert_selector "[data-controller='editor--map'][data-map-ready='true']", wait: 20

    # Outil Point puis clic sur la carte → création d'une feature.
    click_button "Point"
    assert_difference -> { @mapline.map_features.count }, 1 do
      find("[data-editor--map-target='canvas']").click
      assert_selector "[data-editor--features-panel-target='list'] li", count: 1, wait: 10
    end

    feature = @mapline.map_features.first
    assert_equal "point", feature.feature_type
    assert_equal 1, feature.feature_states.count

    # La sélection ouvre l'inspecteur (champ Nom).
    within "[data-controller='editor--features-panel']" do
      first("li button").click
    end
    assert_selector "[data-controller='editor--inspector'] input[data-role='name']"

    # Persistance après rechargement (payload → store).
    visit edit_mapline_path(@mapline)
    assert_selector "[data-editor--features-panel-target='list'] li", count: 1, wait: 10

    # Suppression via l'API (scopée au panneau : d'autres « Supprimer » existent).
    assert_difference -> { @mapline.map_features.count }, -1 do
      within "[data-controller='editor--features-panel']" do
        accept_confirm { click_button "Supprimer" }
      end
      assert_no_selector "[data-editor--features-panel-target='list'] li", wait: 10
    end
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    within("form") { click_button "Se connecter" }
    assert_text "Mes cartes" # en-tête connecté
  end
end
