class Admin::ReportsController < Admin::BaseController
  def index
    scope = Report.includes(:reporter, :reportable).recent
    scope = scope.where(status: params[:status]) if params[:status].present?
    @pagy, @reports = pagy(scope, limit: 30)
  end

  def update
    @report = Report.find(params[:id])

    Report.transaction do
      case params[:decision]
      when "hide"
        @report.reportable.update!(status: :hidden)
        Report.where(reportable: @report.reportable, status: :pending).update_all(
          status: Report.statuses[:resolved],
          resolved_by_id: Current.user.id,
          resolved_at: Time.current,
          updated_at: Time.current
        )
      when "dismiss"
        @report.update!(status: :dismissed, resolved_by: Current.user, resolved_at: Time.current)
      when "restore"
        @report.reportable.update!(status: :published)
        @report.update!(status: :resolved, resolved_by: Current.user, resolved_at: Time.current)
      else
        redirect_to admin_reports_path, alert: "알 수 없는 처리입니다." and return
      end
    end

    redirect_to admin_reports_path, notice: "처리되었습니다."
  end
end
