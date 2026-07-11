class PublicMaplinesController < ApplicationController
  allow_unauthenticated_access

  # Lecture publique d'une carte : /m/:slug
  # Les brouillons ne sont visibles que par leur auteur.
  def show
    mapline = Mapline.find_by!(slug: params[:slug])

    unless mapline.viewable_by?(Current.user)
      raise ActiveRecord::RecordNotFound
    end

    render Views::PublicMaplines::Show.new(mapline: mapline)
  end
end
