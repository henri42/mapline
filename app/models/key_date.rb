# Date clé de la frise : un « chapitre », unité de versionnement des géométries.
#
# Les dates historiques échappent au type `date` SQL (années négatives,
# granularité variable). On stocke donc :
#   - `year` en numérotation astronomique signée (0 = 1 av. J.-C.) ;
#   - `month`/`day` nullables (la granularité découle de leur présence) ;
#   - `sort_key` dérivé, pour un tri chronologique trivial (années < 0 comprises).
#
# La saisie se fait en année *positive* + ère (av./ap. J.-C.) via les attributs
# virtuels `year_input` / `era`, convertis en `year` astronomique avant validation.
class KeyDate < ApplicationRecord
  belongs_to :mapline

  MOIS = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre].freeze

  attribute :year_input, :integer
  attribute :era, :string

  validates :title, length: { maximum: 200 }
  validate :annee_presente
  validate :annee_positive_en_saisie
  validate :mois_dans_lintervalle
  validate :jour_coherent
  validate :date_unique_dans_la_carte

  before_validation :assign_astronomical_year
  before_validation :compute_sort_key

  # Année positive telle que saisie/affichée dans le formulaire.
  def year_input
    saisie = super
    saisie.present? ? saisie : display_year
  end

  # Ère telle que saisie/affichée dans le formulaire : "bc" / "ce".
  def era
    saisie = super
    return saisie if saisie.present?

    bc? ? "bc" : "ce"
  end

  def bc?
    y = effective_year
    y.present? && y <= 0
  end

  # Année en valeur positive pour l'affichage (nil si l'année n'est pas fixée).
  # Fonctionne aussi avant validation (dérive de la saisie année + ère).
  def display_year
    y = effective_year
    return if y.nil?

    y <= 0 ? 1 - y : y
  end

  # Libellé lisible de la date. `label` prime (dates incertaines : « vers 800 ») ;
  # sinon rendu automatique selon la granularité, av. J.-C. géré.
  def display_date
    return label if label.present?

    y = effective_year
    return "" if y.nil?

    millesime = y <= 0 ? "#{1 - y} av. J.-C." : y.to_s

    if month && day
      "#{day} #{MOIS[month - 1]} #{millesime}"
    elsif month
      "#{MOIS[month - 1].capitalize} #{millesime}"
    else
      millesime
    end
  end

  private

  # Année astronomique effective : `year` s'il est posé, sinon dérivée de la
  # saisie brute (année + ère) — permet l'affichage avant `before_validation`.
  def effective_year
    return year unless year.nil?

    saisie = read_attribute(:year_input)
    return if saisie.blank?

    read_attribute(:era) == "bc" ? 1 - saisie : saisie
  end

  # Convertit (année positive + ère) → année astronomique signée. Recalcule
  # à partir de la saisie brute pour qu'une édition modifiant l'année prime
  # sur l'ancien `year` déjà en base.
  def assign_astronomical_year
    saisie = read_attribute(:year_input)
    return if saisie.blank?

    self.year = read_attribute(:era) == "bc" ? 1 - saisie : saisie
  end

  def compute_sort_key
    return if year.nil?

    self.sort_key = year * 10_000 + (month || 1) * 100 + (day || 1)
  end

  def annee_presente
    errors.add(:base, "Indiquez une année.") if year.nil?
  end

  def annee_positive_en_saisie
    saisie = year_input
    return if saisie.blank? || saisie >= 1

    errors.add(:base, "L'année doit être positive ; utilisez l'ère av./ap. J.-C.")
  end

  def mois_dans_lintervalle
    return if month.blank? || (1..12).cover?(month)

    errors.add(:base, "Le mois doit être compris entre 1 et 12.")
  end

  def jour_coherent
    return if day.blank?

    if month.blank?
      errors.add(:base, "Précisez le mois si vous indiquez un jour.")
    elsif !(1..31).cover?(day)
      errors.add(:base, "Le jour doit être compris entre 1 et 31.")
    end
  end

  def date_unique_dans_la_carte
    return if sort_key.blank? || mapline_id.blank?

    siblings = mapline.key_dates.where(sort_key: sort_key)
    siblings = siblings.where.not(id: id) if persisted?

    errors.add(:base, "Une date clé existe déjà à cette date.") if siblings.exists?
  end
end
