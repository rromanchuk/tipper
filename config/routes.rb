Rails.application.routes.draw do
  
  get '/auth/:provider/callback', to: 'sessions#create'

  namespace :api, path: '/', defaults: { format: 'json' } do
    get '/me/refresh' => 'me#show'
    post 'register' => 'me#register'
    delete 'disconnect' => 'me#disconnect'
    post 'connect' => 'me#connect'

    resource :me,                   only: [:create, :show, :index], controller: 'me'
    resources :tips,                only: [:show]
    resources :transactions,        only: [:show]
    resources :charges,             only: [:create]
    resources :cognito,             only: [:create]
    resources :address,             only: [:create]
    resources :users,               only: [:show]
    resources :settings,            only: [:show, :index]
  end


  namespace :admin, path: '/', constraints: { subdomain: /wwwadmin.*/ } do
    resources :users,  only: [:index, :show]
    resources :tips,  only: [:index]
    resources :wallet do
      collection do 
        get 'withdrawals'
        get 'transactions'
      end
    end

    resources :bitcoin_accounts do 
      collection do 
        get 'index'
        get 'recent'
        get 'addresses'
        get 'network'
        get 'balance'
        get 'reserve'
      end

      member do 
        get 'unspent'
      end
    end
    root to: 'users#index'
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/devel/emails"
  end

  post '/sms'           => 'sms#download'
  get '/tip/:tip_id'    => 'index#index', as: 'tip'
  get '/privacy'        => 'index#index'
  get '/login'          => 'index#index'
  post '/logout'        => 'index#index'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  #match "*path", to: "index#index", via: :all
  
  root 'index#index'
end
