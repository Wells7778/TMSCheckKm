Rails.application.routes.draw do
  devise_for :users
  resources :lists, only: [:index, :show, :create] do
    post :generate_km
  end

  root "lists#index"
end
