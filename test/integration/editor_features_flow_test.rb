require "test_helper"

class EditorFeaturesFlowTest < ActionDispatch::IntegrationTest
  setup do
    @mapline = maplines(:alice_public)
    @key_date = key_dates(:vienne)
    sign_in_as users(:one)
  end

  def polygon
    { type: "Polygon", coordinates: [ [ [ 2.0, 48.0 ], [ 3.0, 48.0 ], [ 3.0, 49.0 ], [ 2.0, 48.0 ] ] ] }
  end

  test "créer une feature avec son premier état" do
    assert_difference [ "MapFeature.count", "FeatureState.count" ], 1 do
      post editor_mapline_features_url(@mapline), as: :json, params: {
        feature: {
          feature_type: "area", name: "Royaume",
          state: { key_date_id: @key_date.id, geometry: polygon }
        }
      }
    end

    assert_response :created
    body = response.parsed_body
    assert_equal "area", body["featureType"]
    assert body["states"].key?(@key_date.id.to_s)
  end

  test "refuse une géométrie incompatible avec le type" do
    assert_no_difference "MapFeature.count" do
      post editor_mapline_features_url(@mapline), as: :json, params: {
        feature: {
          feature_type: "area",
          state: { key_date_id: @key_date.id, geometry: { type: "Point", coordinates: [ 2.0, 48.0 ] } }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"].join, "incompatible"
  end

  test "refuse des coordonnées hors bornes" do
    post editor_mapline_features_url(@mapline), as: :json, params: {
      feature: {
        feature_type: "point",
        state: { key_date_id: @key_date.id, geometry: { type: "Point", coordinates: [ 999.0, 0.0 ] } }
      }
    }

    assert_response :unprocessable_entity
  end

  test "mettre à jour le nom et le style d'une feature" do
    feature = @mapline.map_features.create!(feature_type: "area")

    patch editor_feature_url(feature), as: :json,
      params: { feature: { name: "Renommé", style: { fill: "#ff0000" } } }

    assert_response :success
    assert_equal "Renommé", feature.reload.name
    assert_equal "#ff0000", feature.style["fill"]
  end

  test "supprimer une feature" do
    feature = @mapline.map_features.create!(feature_type: "area")

    assert_difference "MapFeature.count", -1 do
      delete editor_feature_url(feature)
    end
    assert_response :no_content
  end

  test "upsert d'un état est idempotent (autosave géométrie)" do
    feature = @mapline.map_features.create!(feature_type: "area")
    url = "/editor/features/#{feature.id}/states/#{@key_date.id}"

    assert_difference "FeatureState.count", 1 do
      put url, as: :json, params: { state: { geometry: polygon } }
    end
    assert_response :success

    moved = { type: "Polygon", coordinates: [ [ [ 5.0, 45.0 ], [ 6.0, 45.0 ], [ 6.0, 46.0 ], [ 5.0, 45.0 ] ] ] }
    assert_no_difference "FeatureState.count" do
      put url, as: :json, params: { state: { geometry: moved } }
    end
    assert_equal 5.0, feature.feature_states.first.geometry["coordinates"][0][0][0]
  end

  test "un auteur ne peut pas toucher la feature d'un autre" do
    feature = @mapline.map_features.create!(feature_type: "area")
    delete session_url
    sign_in_as users(:two)

    patch editor_feature_url(feature), as: :json, params: { feature: { name: "Intrus" } }
    assert_response :not_found
  end

  test "les endpoints éditeur exigent une connexion" do
    delete session_url

    post editor_mapline_features_url(@mapline), as: :json,
      params: { feature: { feature_type: "area" } }
    assert_response :redirect
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
