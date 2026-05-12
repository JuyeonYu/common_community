Rails.application.routes.draw do
  # Google OAuth — 가입/로그인 진입.
  get "/auth/:provider/callback", to: "sessions#create_oauth", as: :oauth_callback
  get "/auth/failure", to: "sessions#failure"

  # 관리자용 이메일+비밀번호 (admin 백오피스 진입용으로만 유지).
  resource :session
  resources :passwords, param: :token

  resources :profiles, only: %i[ show edit update ] do
    member do
      get :history
      get :posts
      get :comments
    end
  end

  # 게시판.
  resources :posts do
    resources :comments, only: %i[ create ]
    resource  :like, only: %i[ create destroy ], module: :posts
  end
  resources :comments, only: %i[ edit update destroy ] do
    resource :like, only: %i[ create destroy ], module: :comments
  end
  resources :tags, only: %i[ show ], param: :slug
  resources :reports, only: %i[ new create ]

  resources :notifications, only: %i[ index ] do
    collection { patch :read_all }
  end

  # 브라우저 Web Push 구독.
  resources :push_subscriptions, only: %i[ create ] do
    collection { delete :unsubscribe }
  end

  # 초대장.
  #   GET    /invitations          — 내가 보낸 초대 목록 + 발급 폼
  #   POST   /invitations          — 새 초대 발급
  #   DELETE /invitations/:id      — 본인이 보낸 pending 초대 취소
  #   GET    /invitations/redeem   — 코드 입력 폼 (잠금 사용자 진입점)
  #   POST   /invitations/redeem   — 코드 적용
  #   GET    /i/:code              — URL 직접 진입 (자동 적용 또는 OAuth로)
  resources :invitations, only: %i[ index create destroy ] do
    collection do
      get  :redeem
      post :redeem, action: :apply_redemption, as: :apply_redemption
    end
  end
  get "/i/:code", to: "invitations#show", as: :invitation_url,
      constraints: { code: /[A-Z2-9]{8}/ }

  # 관리자 백오피스.
  namespace :admin do
    resources :seed_emails, only: %i[ index create destroy ]
    resources :reports, only: %i[ index update ]
    resources :users, only: %i[ index show ] do
      member do
        post   :adjust_score
        post   :grant_credits
        post   :suspend
        post   :unsuspend
      end
    end
  end

  # 헬스체크.
  get "up" => "rails/health#show", as: :rails_health_check

  root "landing#index"
end
