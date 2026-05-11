Rails.application.routes.draw do
  # OAuth (Google)
  get "/auth/:provider/callback", to: "sessions#create_oauth", as: :oauth_callback
  get "/auth/failure", to: "sessions#failure"

  # 기존 인증 (관리자/개발용 이메일+비밀번호)
  resource :session
  resources :passwords, param: :token

  # 콘텐츠
  resources :posts do
    resources :comments, only: %i[ create ]
    resource  :like, only: %i[ create destroy ], module: :posts
  end
  resources :comments, only: %i[ edit update destroy ] do
    resource :like, only: %i[ create destroy ], module: :comments
  end
  resources :tags, only: %i[ show ], param: :slug
  resources :profiles, only: %i[ show edit update ] do
    member do
      get :posts
      get :comments
    end
  end
  resources :reports, only: %i[ new create ]
  resources :notifications, only: %i[ index ] do
    collection { patch :read_all }
  end

  # 브라우저 Web Push 구독. 클라이언트 Service Worker가 만든 subscription 객체를
  # 서버에 등록(create) / 해제(destroy by endpoint in body) 한다.
  resources :push_subscriptions, only: %i[ create ] do
    collection { delete :unsubscribe }
  end

  namespace :admin do
    resources :reports, only: %i[ index update ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "posts#index"
end
