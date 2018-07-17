Rails.application.routes.draw do
  resources :lists, only: [:index, :show, :create] do
    get :generate_km
  end

  root "lists#index"
end
