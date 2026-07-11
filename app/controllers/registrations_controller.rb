class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    render Views::Registrations::New.new(user: User.new)
  end

  def create
    user = User.new(registration_params)

    if user.save
      start_new_session_for user
      redirect_to after_authentication_url, notice: "Bienvenue sur Mapline, #{user.display_name} !"
    else
      render Views::Registrations::New.new(user: user), status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.permit(:email_address, :display_name, :password, :password_confirmation)
  end
end
