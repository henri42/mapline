require "test_helper"

class KeyDateTest < ActiveSupport::TestCase
  setup { @mapline = maplines(:alice_draft) }

  test "calcule sort_key pour une date ap. J.-C. complète" do
    kd = @mapline.key_dates.create!(year_input: 1815, era: "ce", month: 6, day: 18)

    assert_equal 1815, kd.year
    assert_equal 18_150_618, kd.sort_key
  end

  test "convertit une saisie av. J.-C. en année astronomique signée" do
    # 753 av. J.-C. == année astronomique -752.
    kd = @mapline.key_dates.create!(year_input: 753, era: "bc")

    assert_equal(-752, kd.year)
    assert_equal 753, kd.year_input
    assert_equal "bc", kd.era
    assert_predicate kd, :bc?
  end

  test "sort_key ordonne correctement à travers av./ap. J.-C." do
    fondation = @mapline.key_dates.create!(year_input: 753, era: "bc") # -752
    republique = @mapline.key_dates.create!(year_input: 509, era: "bc") # -508
    empire = @mapline.key_dates.create!(year_input: 27, era: "bc")      # -26
    notre_ere = @mapline.key_dates.create!(year_input: 14, era: "ce")   # 14

    ordre = @mapline.key_dates.order(:sort_key).to_a

    assert_equal [ fondation, republique, empire, notre_ere ], ordre
    assert_operator fondation.sort_key, :<, republique.sort_key
    assert_operator empire.sort_key, :<, notre_ere.sort_key
  end

  test "display_date : granularité jour / mois / année" do
    jour = @mapline.key_dates.new(year_input: 1815, era: "ce", month: 6, day: 18)
    mois = @mapline.key_dates.new(year_input: 1815, era: "ce", month: 6)
    annee = @mapline.key_dates.new(year_input: 1815, era: "ce")

    assert_equal "18 juin 1815", jour.display_date
    assert_equal "Juin 1815", mois.display_date
    assert_equal "1815", annee.display_date
  end

  test "display_date : av. J.-C." do
    kd = @mapline.key_dates.new(year_input: 753, era: "bc")

    assert_equal "753 av. J.-C.", kd.display_date
  end

  test "le libellé libre prime sur le rendu automatique" do
    kd = @mapline.key_dates.new(year_input: 800, era: "ce", label: "vers 800")

    assert_equal "vers 800", kd.display_date
  end

  test "l'édition d'une année recalcule year et sort_key" do
    kd = @mapline.key_dates.create!(year_input: 1815, era: "ce")

    kd.update!(year_input: 44, era: "bc")

    assert_equal(-43, kd.year)
    assert_equal(-43 * 10_000 + 101, kd.sort_key)
  end

  test "exige une année" do
    kd = @mapline.key_dates.new(era: "ce", title: "Sans année")

    assert_not kd.valid?
    assert_includes kd.errors.full_messages.join, "année"
  end

  test "rejette un mois hors de l'intervalle" do
    assert_not @mapline.key_dates.new(year_input: 1815, era: "ce", month: 13).valid?
  end

  test "un jour sans mois est incohérent" do
    kd = @mapline.key_dates.new(year_input: 1815, era: "ce", day: 18)

    assert_not kd.valid?
    assert_includes kd.errors.full_messages.join, "mois"
  end

  test "refuse deux dates clés à la même date dans une carte" do
    @mapline.key_dates.create!(year_input: 1815, era: "ce", month: 6, day: 18)
    doublon = @mapline.key_dates.new(year_input: 1815, era: "ce", month: 6, day: 18)

    assert_not doublon.valid?
    assert_includes doublon.errors.full_messages.join, "existe déjà"
  end

  test "la même date est permise dans deux cartes différentes" do
    maplines(:alice_draft).key_dates.create!(year_input: 1815, era: "ce")

    autre = maplines(:alice_public).key_dates.new(year_input: 1815, era: "ce")

    assert autre.valid?
  end

  test "supprimer une carte supprime ses dates clés" do
    mapline = users(:one).maplines.create!(title: "À jeter")
    mapline.key_dates.create!(year_input: 1000, era: "ce")

    assert_difference -> { KeyDate.count }, -1 do
      mapline.destroy
    end
  end
end
