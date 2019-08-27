class DevicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_device, only: [:show, :edit, :update, :destroy, :send_atm_command, :add_cash, :reset_cash, :add_coin, :reset_coin, :get_term_totals, :cash_position]
  load_and_authorize_resource
  
  helper_method :transactions_sort_column, :transactions_sort_direction
  
  # GET /devices
  # GET /devices.json
  def index
#    @devices = current_user.company.devices
    devices = current_user.super? ? Device.all : (current_user.collaborator? and not current_user.devices.blank?) ?  current_user.devices : current_user.company.devices
    @devices = devices.order("description ASC") unless devices.blank?
    
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
#    @transactions = @device.transactions.where(date_time: Date.today.beginning_of_day.last_month..Date.today.end_of_day).order("date_time DESC")
    @start_date = params[:start_date].blank? ?  Date.today.last_week.to_s : params[:start_date]
    @end_date = params[:end_date].blank? ?  Date.today.to_s : params[:end_date]
#    @dev_statuses = @device.dev_statuses.where(date_time: Date.today.beginning_of_day.last_week..Date.today.end_of_day).order("date_time DESC").page(params[:dev_statuses_page]).per(5)
    @dev_statuses = @device.dev_statuses.where(date_time: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).order("date_time DESC").page(params[:dev_statuses_page]).per(5)
    @most_recent_dev_status = @device.dev_statuses.order("date_time DESC").first
    @bill_counts = @device.bill_counts
    
    @separate_coin_device = @device.coin_device
    
    @denoms = @device.denoms
    @bin_1_denomination = @device.bin_1_denomination
    @bin_2_denomination = @device.bin_2_denomination
    @bin_3_denomination = @device.bin_3_denomination
    @bin_4_denomination = @device.bin_4_denomination
    @bin_5_denomination = @device.bin_5_denomination
    @bin_6_denomination = @device.bin_6_denomination
    @bin_7_denomination = @device.bin_7_denomination
    @bin_8_denomination = @device.bin_8_denomination
    
    @bill_hists = @device.bill_hists.select(:cut_dt).distinct.order("cut_dt DESC").first(5)
    @term_totals = params[:term_totals]
    
    @cut_transactions = @device.transactions.cuts.where(date_time: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).select(:date_time, :amt_auth).distinct.order("date_time DESC")
    @add_transactions = @device.transactions.adds.where(date_time: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day)
    @coin_add_transactions = @device.transactions.coin_adds.where(date_time: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day)
    @withdrawal_transactions = @device.transactions.withdrawals.where(date_time: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).order("#{transactions_sort_column} #{transactions_sort_direction}")
    @transactions = @withdrawal_transactions.page(params[:transactions_page]).per(10)
    @transactions_count = @transactions.count unless @transactions.blank?
    @transactions_total = 0
    @transactions_fee_total = 0
    @withdrawal_transactions.each do |transaction|
      @transactions_total = @transactions_total + transaction.amt_auth unless transaction.amt_auth.blank?
      @transactions_fee_total = @transactions_fee_total + transaction.ChpFee unless transaction.ChpFee.blank? or transaction.ChpFee.zero?
    end
    @transactions_average_amount = @transactions_count.blank? ? 0 : @transactions_total / @transactions_count
    
    respond_to do |format|
      format.html {
      }
      format.js { # for endless page
      }
    end
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
  
  def add_cash
    @device.send_atm_down_command
    bin_1 = params[:bin_1].blank? ? 0 : params[:bin_1]
    bin_2 = params[:bin_2].blank? ? 0 : params[:bin_2]
    bin_3 = params[:bin_3].blank? ? 0 : params[:bin_3]
    bin_4 = params[:bin_4].blank? ? 0 : params[:bin_4]
    bin_5 = params[:bin_5].blank? ? 0 : params[:bin_5]
    bin_6 = params[:bin_6].blank? ? 0 : params[:bin_6]
    bin_7 = params[:bin_7].blank? ? 0 : params[:bin_7]
    bin_8 = params[:bin_8].blank? ? 0 : params[:bin_8]
    if @device.add_cash(bin_1, bin_2, bin_3, bin_4, bin_5, bin_6, bin_7, bin_8)
      flash[:notice] = "Cash added."
    else
      flash[:alert] = "There was a problem doing the cash add."
    end
    @device.send_atm_up_command
    redirect_to @device
  end
  
  def reset_cash
    @device.send_atm_down_command
    bin_1 = params[:bin_1].blank? ? 0 : params[:bin_1]
    bin_2 = params[:bin_2].blank? ? 0 : params[:bin_2]
    bin_3 = params[:bin_3].blank? ? 0 : params[:bin_3]
    bin_4 = params[:bin_4].blank? ? 0 : params[:bin_4]
    bin_5 = params[:bin_5].blank? ? 0 : params[:bin_5]
    bin_6 = params[:bin_6].blank? ? 0 : params[:bin_6]
    bin_7 = params[:bin_7].blank? ? 0 : params[:bin_7]
    bin_8 = params[:bin_8].blank? ? 0 : params[:bin_8]
    if @device.reset_cash(bin_1, bin_2, bin_3, bin_4, bin_5, bin_6, bin_7, bin_8)
      flash[:notice] = "Cash reset."
    else
      flash[:alert] = "There was a problem doing the cash reset."
    end
    @device.send_atm_up_command
    redirect_to @device
  end
  
  def add_coin
    @device.send_atm_down_command
    bin_1 = params[:bin_1].blank? ? 0 : params[:bin_1]
    bin_2 = params[:bin_2].blank? ? 0 : params[:bin_2]
    bin_3 = params[:bin_3].blank? ? 0 : params[:bin_3]
    bin_4 = params[:bin_4].blank? ? 0 : params[:bin_4]
    bin_5 = params[:bin_5].blank? ? 0 : params[:bin_5]
    bin_6 = params[:bin_6].blank? ? 0 : params[:bin_6]
    bin_7 = params[:bin_7].blank? ? 0 : params[:bin_7]
    bin_8 = params[:bin_8].blank? ? 0 : params[:bin_8]
    if @device.add_coin(bin_1, bin_2, bin_3, bin_4, bin_5, bin_6, bin_7, bin_8)
      flash[:notice] = "Coin added."
    else
      flash[:alert] = "There was a problem doing the coin add."
    end
    @device.send_atm_up_command
    redirect_to @device
  end
  
  def reset_coin
    @device.send_atm_down_command
    bin_1 = params[:bin_1].blank? ? 0 : params[:bin_1]
    bin_2 = params[:bin_2].blank? ? 0 : params[:bin_2]
    bin_3 = params[:bin_3].blank? ? 0 : params[:bin_3]
    bin_4 = params[:bin_4].blank? ? 0 : params[:bin_4]
    bin_5 = params[:bin_5].blank? ? 0 : params[:bin_5]
    bin_6 = params[:bin_6].blank? ? 0 : params[:bin_6]
    bin_7 = params[:bin_7].blank? ? 0 : params[:bin_7]
    bin_8 = params[:bin_8].blank? ? 0 : params[:bin_8]
    if @device.reset_coin(bin_1, bin_2, bin_3, bin_4, bin_5, bin_6, bin_7, bin_8)
      flash[:notice] = "Coin reset."
    else
      flash[:alert] = "There was a problem doing the coin reset."
    end
    @device.send_atm_up_command
    redirect_to @device
  end
  
  def get_term_totals
    response = @device.get_term_totals
    respond_to do |format|
      format.html {
        flash[:notice] = "Term totals requested."
        redirect_to device_path(@device, term_totals: response)
      }
      format.json {
        render json: { "bin1" => response[:bin1], "bin2" => response[:bin2], "bin3" => response[:bin3], "bin4" => response[:bin4], "bin5" => response[:bin5], "bin6" => response[:bin6], "bin7" => response[:bin7], "bin8" => response[:bin8] }, :status => :ok 
#        render json: {"first_name" => @customer.first_name, "last_name" => @customer.last_name, "balance" => @account.available_balance, "account_id" => @account.id, "customer_barcode_id" => @barcode.blank? ? nil : @barcode.id}
      }
    end
  end
  
  def cash_position
#    @last_change_date = @device.transactions.coin_or_cash_adds_and_cuts.last.date_time
#    @bill_hist_bin_1 = @device.bill_hists.where(cut_dt: (@last_change_date - 2.seconds)..(@last_change_date + 2.seconds), cassette_id: "1").last
#    @bill_hist_bin_2 = @device.bill_hists.where(cut_dt: (@last_change_date - 2.seconds)..(@last_change_date + 2.seconds), cassette_id: "2").last
#    @bill_hist_bin_3 = @device.bill_hists.where(cut_dt: (@last_change_date - 2.seconds)..(@last_change_date + 2.seconds), cassette_id: "3").last
#    @bill_hist_bin_4 = @device.bill_hists.where(cut_dt: (@last_change_date - 2.seconds)..(@last_change_date + 2.seconds), cassette_id: "4").last
#    @bill_hist_bin_5 = @device.bill_hists.where(cut_dt: (@last_change_date - 2.seconds)..(@last_change_date + 2.seconds), cassette_id: "5").last
#    @bill_hist_bin_6 = @device.bill_hists.where(cut_dt: (@last_change_date - 2.seconds)..(@last_change_date + 2.seconds), cassette_id: "6").last
#    @bill_hist_bin_7 = @device.bill_hists.where(cut_dt: (@last_change_date - 2.seconds)..(@last_change_date + 2.seconds), cassette_id: "7").last
#    @bill_hist_bin_8 = @device.bill_hists.where(cut_dt: (@last_change_date - 2.seconds)..(@last_change_date + 2.seconds), cassette_id: "8").last
    
    @bill_count_bin_1 = @device.bill_count_1
    @bill_count_bin_2 = @device.bill_count_2
    @bill_count_bin_3 = @device.bill_count_3
    @bill_count_bin_4 = @device.bill_count_4
    @bill_count_bin_5 = @device.bill_count_5
    @bill_count_bin_6 = @device.bill_count_6
    @bill_count_bin_7 = @device.bill_count_7
    @bill_count_bin_8 = @device.bill_count_8
    
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
      ["tranID", "dev_id", "date_time", "error_code", "tran_status", "amt_auth", "ChpFee"].include?(params[:transactions_column]) ? params[:transactions_column] : "date_time"
    end
end