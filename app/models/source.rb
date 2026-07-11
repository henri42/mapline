class Source < ApplicationRecord
  belongs_to :mapline

  validates :title, presence: true, length: { maximum: 200 }
  validates :url, format: { with: %r{\Ahttps?://[^\s]+\z}i },
    allow_blank: true
  validates :author, length: { maximum: 120 }

  before_validation :set_position, on: :create

  private

  def set_position
    return if position.present? && !position.zero?

    self.position = (mapline&.sources&.maximum(:position) || 0) + 1
  end
end
