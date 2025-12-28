Rails.application.routes.draw do
  # Main events page
  root "events#index"

  # Static pages
  get "about" => "pages#about"
  get "health" => "pages#health"

  # API endpoints
  namespace :api do
    namespace :v1 do
      resources :events, only: [ :index, :show ]
    end
  end

  # Rails health check
  get "up" => "rails/health#show", as: :rails_health_check
end
