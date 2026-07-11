class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    render Views::Home::Index.new
  end
end
