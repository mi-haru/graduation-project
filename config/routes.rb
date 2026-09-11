Rails.application.routes.draw do
  resources :medications, only: %i[index show new create edit update destroy]

  resources :medication_timings, only: [] do
    resource :medication_check, only: %i[create destroy]
  end

  get "home", to: "home#index", as: :home
  devise_for :users
  root "pages#top"

  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
