# frozen_string_literal: true

# Bouton d'action : rend un `button_to` (donc un formulaire) stylé selon
# `variant`. Toute option supplémentaire (method:, form:, data:, params:…)
# est transmise à `button_to`.
#
#   Button("Publier", change_status_mapline_path(m, status: "public"), method: :patch)
#   Button("Se déconnecter", session_path, method: :delete, variant: :ghost)
class Components::Button < Components::Base
  def initialize(label = nil, url = nil, variant: :primary, block: false, method: :post, **attributes)
    @label = label
    @url = url
    @variant = variant
    @block = block
    @method = method
    @extra_class = attributes.delete(:class)
    @attributes = attributes
  end

  def view_template(&content)
    options = { method: @method, class: css, **@attributes }

    if content
      button_to(@url, options, &content)
    else
      button_to(@label, @url, options)
    end
  end

  private

  def css
    button_classes(@variant, block: @block, extra: @extra_class)
  end
end
