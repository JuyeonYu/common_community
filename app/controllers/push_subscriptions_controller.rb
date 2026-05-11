class PushSubscriptionsController < ApplicationController
  # 같은 endpoint로 재구독되면 키 갱신만 하고, 다른 사용자에게 이미 묶여 있어도 현재 유저로 이관.
  def create
    sub = PushSubscription.find_or_initialize_by(endpoint: subscription_params[:endpoint])
    sub.assign_attributes(
      user: Current.user,
      p256dh_key: subscription_params[:p256dh_key],
      auth_key:   subscription_params[:auth_key],
      user_agent: request.user_agent
    )
    sub.save!
    head :created
  end

  # 클라이언트가 unsubscribe() 한 뒤 서버에서도 삭제 요청. endpoint를 body로 받음.
  def unsubscribe
    Current.user.push_subscriptions.where(endpoint: params.require(:endpoint)).destroy_all
    head :no_content
  end

  private
    def subscription_params
      params.expect(push_subscription: %i[ endpoint p256dh_key auth_key ])
    end
end
