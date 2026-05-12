class ReportsController < ApplicationController
  before_action :set_reportable
  helper_method :back_path

  def new
    @report = @reportable.reports.build
  end

  def create
    @report = @reportable.reports.build(reason: params.dig(:report, :reason), reporter: Current.user)

    if @report.save
      redirect_to back_path, notice: "신고가 접수되었습니다. 검토 후 처리해드리겠습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    REPORTABLE_TYPES = %w[ Post Comment ].freeze

    def set_reportable
      type = params[:reportable_type] || params.dig(:report, :reportable_type)
      id   = params[:reportable_id]   || params.dig(:report, :reportable_id)
      raise ActionController::ParameterMissing.new(:reportable_type) unless REPORTABLE_TYPES.include?(type)
      @reportable = type.constantize.find(id)
    end

    def back_path
      case @reportable
      when Post    then post_path(@reportable)
      when Comment then post_path(@reportable.post)
      end
    end
end
