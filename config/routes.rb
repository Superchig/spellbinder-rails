Rails.application.routes.draw do
  post 'invitation/new/:starter_id', to: 'invitation#create'
  get '/invitation/new/:starter_id', to: 'invitation#new', as: :invitation_new
  get 'invitation/show'

  post '/battle/new', to: 'battle#create'
  get 'battle/show'
  get 'battle/search'

  devise_for :users

  get 'home/index'
  root 'home#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
