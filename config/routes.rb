Rails.application.routes.draw do
  # 관리자(시드 사용자) 진입용 이메일+비밀번호. 일반 사용자는 Phase B의 휴대폰 인증으로 가입.
  resource :session
  resources :passwords, param: :token

  resources :profiles, only: %i[ show edit update ]

  resources :notifications, only: %i[ index ] do
    collection { patch :read_all }
  end

  # 브라우저 Web Push 구독.
  resources :push_subscriptions, only: %i[ create ] do
    collection { delete :unsubscribe }
  end

  # 헬스체크 — Kamal 프로브.
  get "up" => "rails/health#show", as: :rails_health_check

  root "landing#index"
end
