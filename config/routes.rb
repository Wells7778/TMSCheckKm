Rails.application.routes.draw do
  resources :lists, only: [:index, :create] do
    get :generate_km
  end

  root "lists#index"
end
