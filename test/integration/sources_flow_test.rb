require "test_helper"

class SourcesFlowTest < ActionDispatch::IntegrationTest
  setup do
    @mapline = maplines(:alice_draft)
    sign_in_as users(:one)
  end

  test "la page de gestion expose le frame Turbo des sources" do
    @mapline.sources.create!(title: "Une source")
    get edit_mapline_url(@mapline)

    assert_response :success
    assert_select "turbo-frame#sources_manager"
    assert_select "turbo-frame#source_#{@mapline.sources.first.id}"
    # Les composants Button/Link produisent les classes attendues.
    assert_select "a.btn.btn-ghost", text: "Modifier"
    assert_select "form button.btn.btn-ghost.text-error-ink", text: "Supprimer"
  end

  test "ajouter une source redirige vers la page de gestion" do
    assert_difference -> { @mapline.sources.count }, 1 do
      post mapline_sources_url(@mapline), params: { source: { title: "Nouvelle source" } }
    end
    assert_redirected_to edit_mapline_url(@mapline)
  end

  test "ajouter une source invalide re-rend le frame sources_manager en 422" do
    post mapline_sources_url(@mapline), params: { source: { title: "" } }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#sources_manager"
  end

  test "l'édition d'une source renvoie son frame en mode formulaire" do
    source = @mapline.sources.create!(title: "À corriger")
    get edit_mapline_source_url(@mapline, source)

    assert_response :success
    assert_select "turbo-frame#source_#{source.id} form"
  end

  test "supprimer une source cible le frame sources_manager" do
    source = @mapline.sources.create!(title: "À supprimer")

    assert_difference -> { @mapline.sources.count }, -1 do
      delete mapline_source_url(@mapline, source)
    end
    assert_redirected_to edit_mapline_url(@mapline)
  end

  test "un auteur ne peut pas ajouter de source à la carte d'un autre" do
    get new_session_url # reset via re-sign-in below not needed; just switch user
    delete session_url
    sign_in_as users(:two)

    post mapline_sources_url(@mapline), params: { source: { title: "Intrus" } }
    assert_response :not_found
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
