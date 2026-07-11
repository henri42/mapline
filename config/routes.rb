Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  # Espace auteur : gestion des cartes et de leurs sources.
  resources :maplines, except: :show do
    member do
      patch :change_status
    end
    resources :sources, only: %i[create edit update destroy]
    resources :key_dates, only: %i[create edit update destroy]
  end

  # Pages publiques : lecture d'une carte et profil auteur.
  get "/m/:slug", to: "public_maplines#show", as: :public_mapline
  get "/@:slug", to: "profiles#show", as: :profile

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
end
