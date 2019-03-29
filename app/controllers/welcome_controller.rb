class WelcomeController < ApplicationController
#  before_action :authenticate_user!

  helper_method :transactions_sort_column, :transactions_sort_direction
  
  def index
    if user_signed_in?
#      if current_user.payee? or current_user.caddy? or current_user.consumer? or current_user.vendor?
#        if not current_user.temporary_password.blank?
#          flash[:error] = "You must update your password."
#          redirect_to edit_registration_path(current_user)
#        else
#          unless current_user.customer.blank?
#            unless current_user.customer.accounts.count > 1
#              redirect_to current_user.customer
#            end
#          else
#            redirect_to users_admin_path(current_user)
#          end
#        end
#      end
      if current_user.administrator? or current_user.basic? or current_user.collaborator?
#        @devices = current_user.devices.order("description ASC")
        @devices = current_user.company.devices.order("description ASC")
        @start_date = params[:start_date] ||= (Date.today - 1.week).to_s
        @end_date = params[:end_date] ||= Date.today.to_s
        @type = params[:type] ||= 'Transfer'
        @customer_id = params[:customer_id] if current_user.admin?
        if params[:device_id].blank?
          @device = @devices.first
        else
          @device = @devices.find_by(dev_id: params[:device_id])
        end
#        @processed_payment_batches = current_user.company.payment_batches.processed.order("created_at DESC").first(3)
#        
        # Device Information
        unless @device.blank?
          @dev_statuses = @device.dev_statuses.where(date_time: Date.today.beginning_of_day.last_week..Date.today.end_of_day).order("date_time DESC").first(5)
          @bill_counts = @device.bill_counts
          @denoms = @device.denoms
          @bill_hists = @device.bill_hists.select(:cut_dt).distinct.order("cut_dt DESC").first(5)
          
          @cut_transactions = @device.transactions.cuts.where(date_time: 3.months.ago..Time.now).select(:date_time, :amt_auth).distinct.order("date_time DESC")
          @add_transactions = @device.transactions.adds.where(date_time: 3.months.ago..Time.now)
          @withdrawal_transactions = @device.transactions.withdrawals.where(date_time: 3.months.ago..Time.now)
          
          # Withdrawals Info
          @withdrawals = @device.transactions.withdrawals.where(date_time: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).order("date_time DESC")
          @withdrawals_week_data = []
          grouped_withdrawals = @withdrawals.group_by{ |t| t.date_time.beginning_of_day }
          (@start_date.to_date..@end_date.to_date).each do |date|
            withdrawals_group_total = 0
            grouped_withdrawals.each do |group, withdrawals|
              if date.beginning_of_day == group
                withdrawals.each do |withdrawals|
                  withdrawals_group_total = withdrawals_group_total + withdrawals.amt_auth.to_f
                end
              end
            end
            @withdrawals_week_data << withdrawals_group_total
          end
          @withdrawals_count = @withdrawals.count
          @withdrawals_amount = 0
          @withdrawals.each do |withdrawal_transaction|
            @withdrawals_amount = @withdrawals_amount + withdrawal_transaction.amt_auth unless withdrawal_transaction.amt_auth.blank?
          end
        end
        
        transactions = current_user.company.transactions.where(date_time: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day)
        @transactions = transactions.order("#{transactions_sort_column} #{transactions_sort_direction}")
        
        # Transfers Info
        @transfers = transactions.transfers.where(date_time: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).order("date_time DESC")
        @transfers_week_data = []
        grouped_transfers = @transfers.group_by{ |t| t.date_time.beginning_of_day }
        (@start_date.to_date..@end_date.to_date).each do |date|
          transfers_group_total = 0
          grouped_transfers.each do |group, transfers|
            if date.beginning_of_day == group
              transfers.each do |transfer|
                transfers_group_total = transfers_group_total + transfer.amt_auth.to_f
              end
            end
          end
          @transfers_week_data << transfers_group_total
        end
        @transfers_count = @transfers.count
        @transfers_amount = 0
        @transfers.each do |transfer_transaction|
          @transfers_amount = @transfers_amount + transfer_transaction.amt_auth unless transfer_transaction.amt_auth.blank?
        end
        
#        @payees_count = current_user.company.customers.count
#        @payees_count = @transfers.group_by{ |t| t.to_acct_id}.count
        
#        @week_of_dates_data = (1.week.ago.to_date..Date.today).map{ |date| date.strftime('%-m/%-d') }
        @week_of_dates_data = (@start_date.to_date..@end_date.to_date).map{ |date| date.strftime('%-m/%-d') }
        
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
    end
  end
  
  private
    ### Secure the transactions sort direction ###
    def transactions_sort_direction
      %w[asc desc].include?(params[:transactions_direction]) ?  params[:transactions_direction] : "desc"
    end

    ### Secure the transactions sort column name ###
    def transactions_sort_column
      ["tranID", "dev_id", "date_time", "error_code", "tran_status", "amt_auth", "ChpFee", "Description"].include?(params[:transactions_column]) ? params[:transactions_column] : "tranID"
    end
  
end
