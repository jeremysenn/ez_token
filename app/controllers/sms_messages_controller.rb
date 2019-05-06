class SmsMessagesController < ApplicationController
  before_action :set_sms_message, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource

  # GET /sms_messages
  # GET /sms_messages.json
  def index
    @start_date = sms_message_params[:start_date] ||= Date.today.to_s
    @end_date = sms_message_params[:end_date] ||= Date.today.to_s
#    sms_messages = current_user.company.sms_messages.where(created_at: @start_date.to_date.in_time_zone(current_user.time_zone).beginning_of_day..@end_date.to_date.in_time_zone(current_user.time_zone).end_of_day)
    @all_sms_messages = current_user.company.sms_messages.where(created_at: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day)
    respond_to do |format|
      format.html {
        @sms_messages = @all_sms_messages.order("created_at DESC").page(params[:page]).per(20)
      }
    end
  end

  # GET /sms_messages/1
  # GET /sms_messages/1.json
  def show
  end

  # GET /sms_messages/new
  def new
    @sms_message = SmsMessage.new
  end

  # GET /sms_messages/1/edit
  def edit
  end

  # POST /sms_messages
  # POST /sms_messages.json
  def create
    @sms_message = SmsMessage.new(sms_message_params)

    respond_to do |format|
      if @sms_message.save
        format.html { redirect_to @sms_message, notice: 'Sms message was successfully created.' }
        format.json { render :show, status: :created, location: @sms_message }
      else
        format.html { render :new }
        format.json { render json: @sms_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sms_messages/1
  # PATCH/PUT /sms_messages/1.json
  def update
    respond_to do |format|
      if @sms_message.update(sms_message_params)
        format.html { redirect_to @sms_message, notice: 'Sms message was successfully updated.' }
        format.json { render :show, status: :ok, location: @sms_message }
      else
        format.html { render :edit }
        format.json { render json: @sms_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sms_messages/1
  # DELETE /sms_messages/1.json
  def destroy
    @sms_message.destroy
    respond_to do |format|
      format.html { redirect_to sms_messages_url, notice: 'Sms message was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sms_message
      @sms_message = SmsMessage.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
#    def sms_message_params
#      params.require(:sms_message).permit(:to, :body, :customer_id, :caddy_id)
#    end
    
    def sms_message_params
      params.fetch(:sms_message, {}).permit(:start_date, :end_date)
    end
end
