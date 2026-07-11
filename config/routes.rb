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

  # Éditeur cartographique : endpoints JSON du canevas (dessin des éléments).
  namespace :editor do
    resources :maplines, only: [] do
      resources :features, only: :create
    end
    resources :features, only: %i[update destroy] do
      put "states/:key_date_id", to: "feature_states#upsert", as: :state
      delete "states/:key_date_id", to: "feature_states#destroy"
    end
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
