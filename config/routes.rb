Rails.application.routes.draw do
  devise_for :users
  resources :posts
  root 'posts#index'
  post '/callback' => 'posts#callback'
end
