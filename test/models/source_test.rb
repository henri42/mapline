require "test_helper"

class SourceTest < ActiveSupport::TestCase
  test "exige un titre" do
    source = maplines(:alice_public).sources.new(title: "")

    assert_not source.valid?
    assert_includes source.errors.attribute_names, :title
  end

  test "rejette une URL invalide mais accepte l'absence d'URL" do
    mapline = maplines(:alice_public)

    assert_not mapline.sources.new(title: "X", url: "pas-une-url").valid?
    assert mapline.sources.new(title: "X").valid?
  end

  test "attribue une position croissante à la création" do
    mapline = maplines(:alice_draft)
    first = mapline.sources.create!(title: "Première")
    second = mapline.sources.create!(title: "Seconde")

    assert_operator second.position, :>, first.position
  end
end
