Rails.application.routes.draw do
  # OAuth (Google)
  get "/auth/:provider/callback", to: "sessions#create_oauth", as: :oauth_callback
  get "/auth/failure", to: "sessions#failure"

  # 기존 인증 (관리자/개발용 이메일+비밀번호)
  resource :session
  resources :passwords, param: :token

  # Black Ticket 가입
  get  "/signup/:token",         to: "registrations#new",         as: :signup
  post "/signup/:token",         to: "registrations#create"
  get  "/signup/:token/verify",  to: "registrations#verify_otp",  as: :verify_signup
  post "/signup/:token/confirm", to: "registrations#confirm_otp", as: :confirm_signup

  resources :invitations, only: %i[ index create destroy ]

  # 콘텐츠
  resources :posts do
    resources :comments, only: %i[ create ]
    resource  :like, only: %i[ create destroy ], module: :posts
  end
  resources :comments, only: %i[ edit update destroy ] do
    resource :like, only: %i[ create destroy ], module: :comments
  end
  resources :tags, only: %i[ show ], param: :slug
  resources :boards, only: %i[ index show ], param: :slug
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

  # 1:1 쪽지 (대화방 + 메시지 + 차단)
  resources :conversations, only: %i[ index show create ] do
    resources :messages, only: %i[ create destroy ], shallow: true
    member { patch :read }
  end
  resources :blocks, only: %i[ index create destroy ]

  namespace :admin do
    root "dashboards#show"
    resource  :dashboard, only: %i[ show ]
    resources :boards
    resources :blacklist_entries, only: %i[ index create destroy ]
    resources :reports, only: %i[ index update ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "posts#index"
end
