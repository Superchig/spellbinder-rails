Rails.application.routes.draw do
  post 'invitation/new/:starter_id', to: 'invitation#create'
  get '/invitation/new/:starter_id', to: 'invitation#new', as: :invitation_new
  get '/invitation', to: 'invitation#index', as: :invitations

  post '/battle/new', to: 'battle#create'
  get '/battle/show/:battle_id', to: 'battle#show', as: :battle
  patch '/battle/orders/:battle_id', to: 'battle#update', as: :battle_orders
  get 'battle/search'
  get '/battle', to: 'battle#index', as: :battles

  devise_for :users

  get 'home/index'
  root 'home#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
