Rails.application.routes.draw do
  resources :lists, onlyr: [:index, :create] do
    get :generate_km
  end

  root "lists#index"
end
