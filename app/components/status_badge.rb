# frozen_string_literal: true

# Pastille de statut d'une carte (brouillon / non répertoriée / publique).
class Components::StatusBadge < Components::Base
  STYLES = {
    "draft" => "bg-line text-muted",
    "unlisted" => "bg-notice-bg text-notice-ink",
    "public" => "bg-primary text-white"
  }.freeze

  LABELS = {
    "draft" => "Brouillon",
    "unlisted" => "Non répertoriée",
    "public" => "Publique"
  }.freeze

  def initialize(status:)
    @status = status
  end

  def view_template
    span(class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold #{STYLES[@status]}") do
      LABELS[@status]
    end
  end
end
