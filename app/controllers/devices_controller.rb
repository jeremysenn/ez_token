class DevicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_device, only: [:show, :edit, :update, :destroy, :send_atm_command]
  load_and_authorize_resource
  
  helper_method :transactions_sort_column, :transactions_sort_direction
  
  # GET /devices
  # GET /devices.json
  def index
#    @devices = current_user.company.devices
    @devices = current_user.devices
    
    # Bin Info
    @bin_1_column_count = @devices.select{ |device| device.bin_1_count != 0 }.select{ |device| device.bin_1_count != nil }.count
    @bin_2_column_count = @devices.select{ |device| device.bin_2_count != 0 }.select{ |device| device.bin_2_count != nil }.count
    @bin_3_column_count = @devices.select{ |device| device.bin_3_count != 0 }.select{ |device| device.bin_3_count != nil }.count
    @bin_4_column_count = @devices.select{ |device| device.bin_4_count != 0 }.select{ |device| device.bin_4_count != nil }.count
    @bin_5_column_count = @devices.select{ |device| device.bin_5_count != 0 }.select{ |device| device.bin_5_count != nil }.count
    @bin_6_column_count = @devices.select{ |device| device.bin_6_count != 0 }.select{ |device| device.bin_6_count != nil }.count
    @bin_7_column_count = @devices.select{ |device| device.bin_7_count != 0 }.select{ |device| device.bin_7_count != nil }.count
    @bin_8_column_count = @devices.select{ |device| device.bin_8_count != 0 }.select{ |device| device.bin_8_count != nil }.count
  end
  
  def show
#    @transactions = @device.transactions.where(DevCompanyNbr: current_user.company_id, date_time: Date.today.beginning_of_day.last_month..Date.today.end_of_day).order("date_time DESC")
    @transactions = @device.transactions.where(date_time: Date.today.beginning_of_day.last_month..Date.today.end_of_day).order("date_time DESC")
    @dev_statuses = @device.dev_statuses.where(date_time: Date.today.beginning_of_day.last_week..Date.today.end_of_day).order("date_time DESC")
    @most_recent_dev_status = @device.dev_statuses.order("date_time DESC").first
    @bill_counts = @device.bill_counts
    @denoms = @device.denoms
    @bill_hists = @device.bill_hists.select(:cut_dt).distinct.order("cut_dt DESC").first(5)
    
    @cut_transactions = @device.transactions.cuts.where(date_time: 3.months.ago..Time.now).select(:date_time, :amt_auth).distinct.order("date_time DESC")
    @add_transactions = @device.transactions.adds.where(date_time: 3.months.ago..Time.now)
    @withdrawal_transactions = @device.transactions.withdrawals.where(date_time: 3.months.ago..Time.now)
  end
  
  def send_atm_command
    respond_to do |format|
      format.html {
        command = params[:command]
        if command == "atm_reset"
          response = @device.send_atm_reset_command
        elsif command == "atm_load"
          response = @device.send_atm_load_command
        elsif command == "atm_up"
          response = @device.send_atm_up_command
        elsif command == "atm_down"
          response = @device.send_atm_down_command
        elsif command == "atm_disconnect"
          response = @device.send_atm_disconnect_command
        end
        redirect_back fallback_location: @device, notice: "Command #{command} sent."
      }
      format.json {
        command = params[:command]
        if command == "atm_reset"
          response = @device.send_atm_reset_command
        elsif command == "atm_load"
          response = @device.send_atm_load_command
        elsif command == "atm_up"
          response = @device.send_atm_up_command
        elsif command == "atm_down"
          response = @device.send_atm_down_command
        elsif command == "atm_disconnect"
          response = @device.send_atm_disconnect_command
        end
        render json: { "response" => response }, :status => :ok 
      }
    end
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_device
      @device = Device.find(params[:id])
    end
    
    ### Secure the transactions sort direction ###
    def transactions_sort_direction
      %w[asc desc].include?(params[:transactions_direction]) ?  params[:transactions_direction] : "desc"
    end

    ### Secure the transactions sort column name ###
    def transactions_sort_column
      ["tranID", "dev_id", "date_time", "error_code", "tran_status", "amt_auth", "ChpFee"].include?(params[:transactions_column]) ? params[:transactions_column] : "tranID"
    end
end