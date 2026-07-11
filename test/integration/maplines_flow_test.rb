require "test_helper"

class MaplinesFlowTest < ActionDispatch::IntegrationTest
  test "le tableau de bord exige une authentification" do
    get maplines_url
    assert_redirected_to new_session_url
  end

  test "un auteur crée une carte puis atterrit sur sa page de gestion" do
    sign_in_as users(:one)

    assert_difference -> { users(:one).maplines.count }, 1 do
      post maplines_url, params: { mapline: { title: "Ma nouvelle carte" } }
    end

    mapline = users(:one).maplines.order(:created_at).last
    assert_redirected_to edit_mapline_url(mapline)
  end

  test "enregistre la vue initiale via PATCH JSON" do
    sign_in_as users(:one)
    mapline = maplines(:alice_draft)

    patch mapline_url(mapline, format: :json),
      params: { mapline: { center_lng: 2.3522, center_lat: 48.8566, zoom: 5.5 } }.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    mapline.reload
    assert_in_delta 2.3522, mapline.center_lng, 0.0001
    assert_in_delta 48.8566, mapline.center_lat, 0.0001
    assert_in_delta 5.5, mapline.zoom, 0.0001
  end

  test "un non-propriétaire ne peut pas modifier la vue initiale (JSON)" do
    sign_in_as users(:two)
    patch mapline_url(maplines(:alice_draft), format: :json),
      params: { mapline: { zoom: 9 } }.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :not_found
  end

  test "publier sans source échoue et reste en brouillon" do
    sign_in_as users(:one)
    mapline = maplines(:alice_draft)

    patch change_status_mapline_url(mapline, status: "public")

    assert_predicate mapline.reload, :draft?
    assert_redirected_to edit_mapline_url(mapline)
  end

  test "une carte publique est consultable par un visiteur anonyme" do
    get public_mapline_url(maplines(:alice_public).slug)
    assert_response :success
    # La carte est câblée sur le contrôleur Stimulus avec la vue initiale.
    assert_select "[data-controller='map'][data-map-zoom-value]"
    assert_select "[data-map-target='canvas']"
  end

  test "l'éditeur cartographique est câblé sur ses contrôleurs Stimulus" do
    sign_in_as users(:one)
    get edit_mapline_url(maplines(:alice_draft))

    assert_response :success
    assert_select "[data-controller='editor--map'][data-editor--map-save-url-value]"
    assert_select "button[data-action='editor--map#saveInitialView']"
    assert_select "[data-controller='editor--toolbar']"
    assert_select "script#editor-payload"
  end

  test "un brouillon est introuvable pour un non-propriétaire" do
    get public_mapline_url(maplines(:alice_draft).slug)
    assert_response :not_found
  end

  test "un brouillon est consultable par son auteur" do
    sign_in_as users(:one)
    get public_mapline_url(maplines(:alice_draft).slug)
    assert_response :success
  end

  test "un auteur ne peut pas modifier la carte d'un autre" do
    sign_in_as users(:two)
    get edit_mapline_url(maplines(:alice_public))
    assert_response :not_found
  end

  test "le profil ne liste que les cartes publiques pour un visiteur" do
    get profile_url(users(:one).slug)
    assert_response :success
    assert_match "Europe en 1815", @response.body
    assert_no_match "Brouillon", @response.body
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
