Rails.application.routes.draw do
  # Google OAuth — 가입/로그인 진입.
  get "/auth/:provider/callback", to: "sessions#create_oauth", as: :oauth_callback
  get "/auth/failure", to: "sessions#failure"

  # 세션은 Google OAuth로만 생성. new는 로그인 진입 페이지, destroy는 로그아웃.
  resource :session, only: %i[ new destroy ]

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

  # 이성 매칭 (Phase D-1: 토글만, D-2부터 풀/커넥트).
  #   GET    /matching        — 진입 화면 (조건 체크리스트 또는 풀)
  #   POST   /matching/enable — 활성화
  #   DELETE /matching        — 일시 중지
  resource :matching, only: %i[ show destroy ], controller: "matching" do
    post :enable
  end
  # 매칭 후보 풀 프로필 (제한된 노출).
  get "/matching/candidates/:id", to: "matching/candidates#show",
      as: :matching_candidate, constraints: { id: /\d+/ }

  resources :connect_requests, only: %i[ create destroy ] do
    member do
      post :accept
      post :reject
    end
  end

  # 성사된 커넥트(채팅방) + 비추천.
  resources :red_connects, only: %i[ index show destroy ] do
    resources :chat_messages, only: %i[ create ]
    resource  :downvote,     only: %i[ create ]
  end

  # 초대장.
  #   GET    /invitations      — 내가 보낸 초대 목록 + 발급 폼
  #   POST   /invitations      — 새 초대 발급
  #   DELETE /invitations/:id  — 본인이 보낸 pending 초대 취소
  #   POST   /invitations/:id/resend — 메일 재발송
  #   GET    /i/:code          — URL 직접 진입 (메일 링크에서 호출)
  resources :invitations, only: %i[ index create edit update destroy ] do
    member { post :resend }
    collection { post :request_recommendation }
  end
  get "/i/:code", to: "invitations#show", as: :invite_link,
      constraints: { code: /[A-Z2-9]{8}/ }

  # 관리자 백오피스.
  namespace :admin do
    root "dashboard#index"
    resources :seed_emails, only: %i[ index create destroy ]
    resources :reports, only: %i[ index update ]
    resources :posts, only: %i[ index destroy ] do
      member do
        post :hide
        post :unhide
      end
    end
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

  # 개발 환경 이메일 프리뷰.
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  root "landing#index"
end
