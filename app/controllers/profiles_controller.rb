class ProfilesController < ApplicationController
  allow_unauthenticated_access

  # Profil auteur public : /@:slug
  def show
    user = User.find_by!(slug: params[:slug])
    owner = Current.user == user

    # Le propriétaire voit toutes ses cartes ; les visiteurs, les publiques.
    maplines = owner ? user.maplines.order(updated_at: :desc) : user.maplines.listed.order(published_at: :desc)

    render Views::Profiles::Show.new(user: user, maplines: maplines, owner: owner)
  end
end
