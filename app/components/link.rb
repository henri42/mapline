# frozen_string_literal: true

# Lien de navigation. Sans `variant`, c'est un lien normal ; avec `variant`
# (:primary / :ghost / :danger), il est stylé comme un bouton.
#
#   Link("Mes cartes", maplines_path, variant: :ghost)
#   Link("Se connecter", new_session_path)
class Components::Link < Components::Base
  def initialize(label = nil, url = nil, variant: nil, block: false, **attributes)
    @label = label
    @url = url
    @variant = variant
    @block = block
    @extra_class = attributes.delete(:class)
    @attributes = attributes
  end

  def view_template(&content)
    options = { class: css, **@attributes }

    if content
      link_to(@url, options, &content)
    else
      link_to(@label, @url, options)
    end
  end

  private

  def css
    variant = @variant ? button_classes(@variant, block: @block) : nil
    [ variant, @extra_class ].compact.join(" ").presence
  end
end
