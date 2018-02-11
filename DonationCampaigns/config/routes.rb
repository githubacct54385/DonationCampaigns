Rails.application.routes.draw do
  get 'sessions/new'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root   'campaigns#home'
  get    '/about',   to: 'campaigns#about'
  post   '/charges', to: 'charges#create'
  get    '/signup',  to: 'users#new'
  post   '/signup',  to: 'users#create'
  get    '/StripeConnected', to: 'users#StripeConnected'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  resources :campaigns
  resources :users
end
