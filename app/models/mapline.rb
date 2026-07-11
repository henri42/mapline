class Mapline < ApplicationRecord
  belongs_to :user
  has_many :sources, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :mapline

  # draft   : visible du seul auteur
  # unlisted : accessible par lien direct, non listée
  # public  : listée sur le profil / l'accueil
  # `scopes: false` : évite d'écraser `Module#public` par un scope `Mapline.public`.
  enum :status, { draft: "draft", unlisted: "unlisted", public: "public" },
    default: "draft", validate: true, scopes: false

  scope :listed, -> { where(status: "public") }
  scope :accessible_by_link, -> { where(status: %w[unlisted public]) }

  validates :title, presence: true, length: { maximum: 120 }
  validates :slug, presence: true, uniqueness: true

  # Exigences portées par la publication, pas par la création (contexte :publish).
  validate :must_have_a_source, on: :publish

  before_validation :ensure_slug, on: :create

  # Une carte est-elle consultable par `viewer` (peut être nil) ?
  def viewable_by?(viewer)
    return true unless draft?

    viewer.present? && viewer == user
  end

  # Transition vers un statut publié (public/unlisted) : valide les prérequis.
  def publish_as(new_status)
    self.status = new_status
    self.published_at ||= Time.current
    save(context: :publish)
  end

  def revert_to_draft
    update(status: "draft")
  end

  # « vers 800 » : réservé aux dates ; ici affichage lisible du statut.
  def status_label
    { "draft" => "Brouillon", "unlisted" => "Non répertoriée", "public" => "Publique" }[status]
  end

  private

  def ensure_slug
    return if slug.present?

    base = title.to_s.parameterize.presence || "carte"
    self.slug = "#{base}-#{SecureRandom.alphanumeric(6).downcase}"
  end

  def must_have_a_source
    return if sources.reject(&:marked_for_destruction?).any?

    errors.add(:base, "Ajoutez au moins une source avant de publier.")
  end
end
