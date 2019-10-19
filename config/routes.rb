Rails.application.routes.draw do
  resources :posts
  root 'posts#index'
  post '/callback' => 'posts#callback'
end
