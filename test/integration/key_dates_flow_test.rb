require "test_helper"

class KeyDatesFlowTest < ActionDispatch::IntegrationTest
  setup do
    @mapline = maplines(:alice_draft)
    sign_in_as users(:one)
  end

  test "la page de gestion expose le frame Turbo des dates clés" do
    key_date = @mapline.key_dates.create!(year_input: 1789, era: "ce")
    get edit_mapline_url(@mapline)

    assert_response :success
    assert_select "turbo-frame#key_dates_manager"
    assert_select "turbo-frame#key_date_#{key_date.id}"
  end

  test "ajouter une date clé redirige vers la page de gestion" do
    assert_difference -> { @mapline.key_dates.count }, 1 do
      post mapline_key_dates_url(@mapline),
        params: { key_date: { year_input: 1789, era: "ce", title: "Révolution" } }
    end
    assert_redirected_to edit_mapline_url(@mapline)
  end

  test "ajouter une date clé av. J.-C. stocke une année astronomique négative" do
    post mapline_key_dates_url(@mapline),
      params: { key_date: { year_input: 44, era: "bc" } }

    assert_equal(-43, @mapline.key_dates.last.year)
  end

  test "ajouter une date clé invalide re-rend le frame key_dates_manager en 422" do
    post mapline_key_dates_url(@mapline), params: { key_date: { year_input: "" } }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#key_dates_manager"
  end

  test "l'édition d'une date clé renvoie son frame en mode formulaire" do
    key_date = @mapline.key_dates.create!(year_input: 1789, era: "ce")
    get edit_mapline_key_date_url(@mapline, key_date)

    assert_response :success
    assert_select "turbo-frame#key_date_#{key_date.id} form"
  end

  test "supprimer une date clé cible le frame key_dates_manager" do
    key_date = @mapline.key_dates.create!(year_input: 1789, era: "ce")

    assert_difference -> { @mapline.key_dates.count }, -1 do
      delete mapline_key_date_url(@mapline, key_date)
    end
    assert_redirected_to edit_mapline_url(@mapline)
  end

  test "un auteur ne peut pas ajouter de date clé à la carte d'un autre" do
    delete session_url
    sign_in_as users(:two)

    post mapline_key_dates_url(@mapline),
      params: { key_date: { year_input: 1789, era: "ce" } }
    assert_response :not_found
  end

  test "la page publique affiche la frise quand des dates clés existent" do
    get public_mapline_url(maplines(:alice_public).slug)

    assert_response :success
    assert_select "[data-controller='timeline']"
    assert_select "[data-timeline-target='tick']", count: 2
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
