class AchLogsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  
  def index
    
    @events = current_user.super? ? Event.all : current_user.collaborator? ? current_user.admin_events : current_user.company.events
    @start_date = params[:start_date].blank? ? Date.today.last_week.to_s : params[:start_date]
    @end_date = params[:end_date].blank? ? Date.today.to_s : params[:end_date]
    @type = params[:type].blank? ? 1 : params[:type]
    
    if current_user.collaborator?
      if params[:event_id].blank?
        unless current_user.admin_events.empty?
          @event_id = current_user.admin_events.first.id
        end
      else
        @event_id = params[:event_id]
      end
    else
      @event_id = params[:event_id]
    end
    @ach_logs= @event_id.blank? ? current_user.company.ach_logs.where(IsClubCSV: @type, CreateDate: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).order("CreateDate DESC") : current_user.company.ach_logs.where(IsClubCSV: @type, event_id: @event_id, CreateDate: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).order("CreateDate DESC")
  end
  
  def show
    @ach_log = AchLog.find(params[:id])
    respond_to do |format|
      format.html {}
      format.csv { 
        send_data @ach_log.decoded_csv_report, filename: "ACHLog-#{@ach_log.ID}-#{@ach_log.CreateDate} - #{Time.now}.csv" 
        }
    end
  end
  
end
