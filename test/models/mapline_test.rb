require "test_helper"

class MaplineTest < ActiveSupport::TestCase
  test "génère un slug à partir du titre à la création" do
    mapline = users(:one).maplines.create!(title: "L'Empire romain d'Occident")

    assert_match(/\Al-empire-romain-d-occident-[a-z0-9]{6}\z/, mapline.slug)
  end

  test "statut par défaut : brouillon" do
    assert users(:one).maplines.new.draft?
  end

  test "refuse la publication sans source (contexte :publish)" do
    mapline = maplines(:alice_draft)

    assert_not mapline.publish_as("public")
    assert_includes mapline.errors.full_messages.join, "source"
    assert_predicate mapline.reload, :draft?
  end

  test "publie quand au moins une source est présente" do
    mapline = maplines(:alice_draft)
    mapline.sources.create!(title: "Une source")

    assert mapline.publish_as("public")
    assert_predicate mapline.reload, :public?
    assert_not_nil mapline.published_at
  end

  test "création sans source reste valide (validation seulement à la publication)" do
    mapline = users(:one).maplines.new(title: "Sans source")

    assert mapline.valid?
  end

  test "viewable_by? : un brouillon n'est visible que par son auteur" do
    draft = maplines(:alice_draft)

    assert draft.viewable_by?(users(:one))
    assert_not draft.viewable_by?(users(:two))
    assert_not draft.viewable_by?(nil)
  end

  test "viewable_by? : une carte publique est visible de tous" do
    public_mapline = maplines(:alice_public)

    assert public_mapline.viewable_by?(nil)
    assert public_mapline.viewable_by?(users(:two))
  end

  test "revert_to_draft repasse la carte en brouillon" do
    mapline = maplines(:alice_public)

    assert mapline.revert_to_draft
    assert_predicate mapline.reload, :draft?
  end
end
