class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true, length: { maximum: 60 }
  validates :slug, presence: true, uniqueness: true
  validates :website_url, format: { with: %r{\Ahttps?://[^\s]+\z}i },
    allow_blank: true

  before_validation :ensure_slug, on: :create

  private

  def ensure_slug
    return if slug.present?

    base = display_name.to_s.parameterize.presence || "user"
    self.slug = "#{base}-#{SecureRandom.alphanumeric(6).downcase}"
  end
end
