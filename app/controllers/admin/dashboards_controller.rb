class Admin::DashboardsController < Admin::BaseController
  def show
    @stats = {
      posts:    Post.count,
      comments: Comment.count,
      users:    User.count,
      pending_reports: Report.pending.count
    }
  end
end
