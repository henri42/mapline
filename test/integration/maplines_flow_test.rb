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
