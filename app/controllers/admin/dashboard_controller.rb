class Admin::DashboardController < Admin::BaseController
  def index
    @user_count       = User.count
    @active_user_count = User.where(matching_enabled: true).count
    @pending_invitation_count = Invitation.where(status: :pending).count
    @open_report_count = Report.where(status: 0).count
    @post_count = Post.count
    @active_red_connect_count = RedConnect.where(status: :active).count
  end
end
