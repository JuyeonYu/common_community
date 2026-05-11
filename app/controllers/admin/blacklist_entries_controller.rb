class Admin::BlacklistEntriesController < Admin::BaseController
  before_action :set_entry, only: %i[ destroy ]

  def index
    @entries = BlacklistEntry.order(created_at: :desc).limit(100)
    @entry = BlacklistEntry.new
  end

  def create
    @entry = BlacklistEntry.new(entry_params.merge(created_by: Current.user))
    if @entry.save
      redirect_to admin_blacklist_entries_path, notice: "블랙리스트에 추가했습니다."
    else
      @entries = BlacklistEntry.order(created_at: :desc).limit(100)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy
    redirect_to admin_blacklist_entries_path, notice: "삭제했습니다.", status: :see_other
  end

  private
    def set_entry
      @entry = BlacklistEntry.find(params[:id])
    end

    def entry_params
      params.expect(blacklist_entry: [ :name, :phone, :reason ])
    end
end
