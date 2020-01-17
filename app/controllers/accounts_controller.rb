class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [:show, :edit, :update, :destroy, :one_time_payment, :send_barcode_link_sms_message]
  load_and_authorize_resource

  # GET /accounts
  # GET /accounts.json
  def index
    @active = params[:active].blank? ? [1,0] : params[:active]
    @events = current_user.super? ? Event.all : current_user.collaborator? ? current_user.admin_events : current_user.company.events
    @account_types = current_user.super? ? AccountType.all : current_user.company.account_types
    unless @account_types.blank?
      @type_id = params[:type_id]
    end
    unless @events.blank?
      @event_id = params[:event_id] #||= @events.first.id
    end
    account_records = current_user.super? ? Account.all : current_user.company.accounts
    accounts = @type_id.blank? ? account_records.where(Active: @active) : account_records.where(ActTypeID: @type_id, Active: @active)
    unless params[:q].blank?
      @query_string = "%#{params[:q]}%"
#      @accounts = current_user.company.accounts.where(ActID: @query_string)
      @total_accounts_results = @event_id.blank? ? accounts : accounts.joins(:events).where(events: {id: @event_id})
      @total_accounts_results = @total_accounts_results.joins(:customers).where("CONCAT(customer.NameF, ' ', customer.NameL) like ? OR customer.NameF like ? OR customer.NameL like ? OR customer.PhoneMobile like ?", @query_string, @query_string, @query_string, @query_string).order("customer.NameL ASC")
      @accounts = @total_accounts_results.page(params[:page]).per(20)
    else
#      @accounts = current_user.company.accounts.where(ActTypeID: @type_id).joins(:events).where(events: {id: @event_id})
      @total_accounts_results = @event_id.blank? ? accounts.distinct : accounts.joins(:events).where(events: {id: @event_id}).distinct
      @total_accounts_results = @total_accounts_results.joins(:customers)#.order("customer.NameL ASC")
      @accounts = @total_accounts_results.page(params[:page]).per(20)
    end
    respond_to do |format|
      format.html {}
      format.json {
#        @customers = Kaminari.paginate_array(results).page(params[:page]).per(10)
#        render json: @customers.map{|c| c['Id']}
#        @customers = results.map {|customer| ["#{customer['FirstName']} #{customer['LastName']}", customer['Id']]}
        unless @total_accounts_results.blank?
          @accounts = @total_accounts_results.collect{ |account| {id: account.CustomerID, text: account.customer_user_name} }.uniq
        else
          @accounts = nil
        end
        Rails.logger.info "results: {#{@accounts}}"
        render json: {results: @accounts}
      }
    end
  end

  # GET /accounts/1
  # GET /accounts/1.json
  def show
#    @customer = @account.customer
    @customers = @account.customers
  end

  # GET /accounts/new
  def new
    @account = Account.new
  end

  # GET /accounts/1/edit
  def edit
#    @customer = @account.customer
    @customers = @account.customers
    @events = current_user.super? ? Event.all : current_user.collaborator? ? current_user.admin_events : current_user.company.events
  end

  # POST /accounts
  # POST /accounts.json
  def create
    @account = Account.new(account_params)
    @events = current_user.super? ? Event.all : current_user.collaborator? ? current_user.admin_events : current_user.company.events
    respond_to do |format|
      if @account.save
        format.html { redirect_to @account, notice: 'Account was successfully created.' }
        format.json { render :show, status: :created, location: @account }
      else
        format.html { render :new }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /accounts/1
  # PATCH/PUT /accounts/1.json
  def update
    respond_to do |format|
      @events = current_user.super? ? Event.all : current_user.collaborator? ? current_user.admin_events : current_user.company.events
      if @account.update(account_params)
#        format.html { redirect_to @account, notice: 'Wallet was successfully updated.' }
        format.html { redirect_to @account, notice: 'Wallet was successfully updated.' }
        format.json { render :show, status: :ok, location: @account }
      else
        format.html { render :edit }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def one_time_payment
    amount = params[:amount].to_f.abs unless params[:amount].blank?
    note = params[:note]
    receipt_number = params[:receipt_number]
    to_customer_id = params[:to_customer_id]
    if params[:pay_and_text]
      response = @account.one_time_payment(amount, note, receipt_number)
    else
      response = @account.one_time_payment_with_no_text_message(amount, note, receipt_number)
    end
    response_code = response[:return]
    unless response_code.to_i > 0
      transaction_id = response[:tran_id]
    else
      error_code = response_code
    end
    Rails.logger.debug "*********************************One time payment transaction ID: #{transaction_id}"
    unless transaction_id.blank?
#      redirect_back fallback_location: @account.customer, notice: 'One time payment submitted.'
#      redirect_to @account.customer, notice: 'One time payment submitted.'
      flash[:notice] = "One time payment submitted."
      redirect_to customer_path(to_customer_id, account_id: @account.id)
    else
      error_description = ErrorDesc.find_by(error_code: error_code)
#      redirect_back fallback_location: root_path, alert: "There was a problem creating the one time payment. Error code: #{error_description.blank? ? 'Unknown' : error_description.long_desc}"
#      redirect_to @account.customer, alert: "There was a problem creating the one time payment. Error code: #{error_description.blank? ? 'Unknown' : error_description.long_desc}"
      flash[:alert] = "There was a problem creating the one time payment. Error code: #{error_description.blank? ? 'Unknown' : error_description.long_desc}"
      redirect_to customer_path(to_customer_id, account_id: @account.id)
    end
  end

  # DELETE /accounts/1
  # DELETE /accounts/1.json
  def destroy
    @account.destroy
    respond_to do |format|
      format.html { redirect_to accounts_url, notice: 'Wallet was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def twilio_send_sms_message
    @message_body = params[:message_body]
    unless params[:account_ids].blank?
      params[:account_ids].each do |account_id|
        account = Account.where(ActID: account_id).first
        unless account.blank?
          account.customers.each do |customer|
  #          account.customer.twilio_send_sms_message(@message_body, current_user.id) unless account.blank? or account.customer.blank?
            customer.twilio_send_sms_message(@message_body, current_user.id)
          end
        end
      end
      redirect_back fallback_location: accounts_path, notice: 'Text message sent.'
    else
      redirect_back fallback_location: accounts_path, alert: 'You must select at least one account to text message.'
    end
  end
  
  def withdraw_barcode
    unless @account.blank?
#      if params[:withdrawal_amount].blank?
      if params[:amount].blank?
        qrcode_number = @account.withdraw_barcode(0)
        @amount = @account.available_balance
      else
#        @amount = params[:withdrawal_amount]
        @amount = params[:amount]
        qrcode_number = @account.withdraw_barcode(@amount)
      end
      @image = helpers.generate_qr(qrcode_number)
    end
    respond_to do |format|
      format.html {
        unless @account.customers and @account.users.include?(current_user)
          flash[:alert] = "You are not authorized to view this page."
          redirect_to root_path
        end
      }
      format.json{
#        if @account.customer and @account.customer.user and @account.customer.user == current_user 
        if @account.customers and @account.users.include?(current_user)
          render json: {"barcode_string" => @image}
        else
          render json: { error: ["Error: Problem generating QR Code."] }, status: :unprocessable_entity
        end
      }
    end
  end
  
  def send_barcode_link_sms_message
    respond_to do |format|
      format.html {
        customer_id = params[:customer_id]
#        unless @account.blank? or @account.customer.blank? or @account.customer.phone.blank?
        unless @account.blank? or @account.customers.blank?
          barcode_number = @account.withdraw_barcode(params[:withdrawal_amount].blank? ? 0 : params[:withdrawal_amount])
          @account.send_barcode_link_sms_message(barcode_number)
#          redirect_to @account.customer, notice: 'Text message sent.'
          redirect_to customer_path(customer_id, account_id: @account.id), notice: 'Text message sent.'
        else
          redirect_back fallback_location: customer_path(customer_id, account_id: @account.id), alert: 'There was a problem sending the barcode link.'
        end
      }
      format.json{
#        unless @account.blank? or @account.customer.blank? or @account.customer.phone.blank?
        unless @account.blank? or @account.customers.blank?
          barcode_number = @account.withdraw_barcode(params[:withdrawal_amount].blank? ? 0 : params[:withdrawal_amount])
          @account.send_barcode_link_sms_message(barcode_number)
          render json: {"barcode_number" => barcode_number}, status: :ok
        else
          render json: { error: ["Error: Problem generating QR Code."] }, status: :unprocessable_entity
        end
      }
    end
  end
  
  # GET /accounts/balances
  # GET /accounts/balances.json
  # GET /accounts/balances.csv
  def balances
    @events = current_user.super? ? Event.all : current_user.collaborator? ? current_user.admin_events : current_user.company.events
    @account_types = current_user.super? ? AccountType.all : current_user.company.account_types
    @company = current_user.company
    @sign = params[:sign].blank? ? 'Negative' : params[:sign]
    unless @account_types.blank?
      @type_id = params[:type_id]
    end
    unless @events.blank?
      @event_id = params[:event_id] #||= @events.first.id
      @event = Event.find(@event_id) unless @event_id.blank?
    end
    account_records = current_user.super? ? (@sign == 'Negative' ? Account.where("Balance < ?", 0) : Account.where("Balance > ?", 0)) : (@sign == 'Negative' ? current_user.company.accounts.where("Balance < ?", 0) : current_user.company.accounts.where("Balance > ?", 0))
    accounts = @type_id.blank? ? account_records : account_records.where(ActTypeID: @type_id)
    @total_accounts_results = @event_id.blank? ? accounts : accounts.joins(:events).where(events: {id: @event_id})
#    @total_accounts_results = @total_accounts_results.joins(:customer).order("customer.NameL ASC")
    @total_accounts_results = @total_accounts_results.order("ActTypeID ASC")
    @accounts = @total_accounts_results.page(params[:page]).per(20)
    @balances_sum = 0
    @total_accounts_results.each do |a|
      @balances_sum = @balances_sum + a.Balance
    end
    
    respond_to do |format|
      format.html {}
      format.json {
        render json: {results: @accounts}
      }
      format.csv { 
        send_data @total_accounts_results.to_csv, filename: "accounts-with-balances-#{Time.now}.csv" 
      }
    end
  end
  
  # GET /accounts/bill_members
  def bill_members
    respond_to do |format|
      format.html {
        events = current_user.super? ? Event.all : current_user.collaborator? ? current_user.admin_events : current_user.company.events
        unless params[:event_id].blank? or params[:club_account_id].blank? or params[:run_transactions_boolean].blank?
          event = events.find(params[:event_id])
          if current_user.company.TxnActID and current_user.company.TxnActID.to_s == params[:club_account_id] and not event.blank?
            bill_members_response = Account.bill_members(params[:event_id], params[:club_account_id], params[:run_transactions_boolean])
            if bill_members_response
              club_report_id = bill_members_response[:club_report_id]
              details_report_id = bill_members_response[:details_report_id]
              redirect_to balances_accounts_path(event_id: params[:event_id], type_id: params[:type_id], club_report_id: club_report_id, details_report_id: details_report_id), notice: 'BillMembers successfully called.'
            else
              redirect_to balances_accounts_path(event_id: params[:event_id], type_id: params[:type_id]), alert: 'There was a problem calling BillMembers - no response.'
            end
          else
            redirect_to balances_accounts_path(event_id: params[:event_id], type_id: params[:type_id]), alert: 'There was a problem calling BillMembers.'
          end
        else
          redirect_to balances_accounts_path(event_id: params[:event_id], type_id: params[:type_id]), alert: 'There was a problem calling BillMembers - missing parameters.'
        end
      }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_account
      @account = Account.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
#    def account_params
#      params.require(:account).permit(:to, :body, :customer_id, :caddy_id)
#    end
    
    def account_params
      params.require(:account).permit(:Balance, :Active, :MinBalance, :ActTypeID, :AbleToDelete, :MaintainBal, :BankActNbr, :BankActNbr_confirmation, :RoutingNbr, 
        :cc_charge_amount, :cc_number, :cc_expiration, :cc_cvc, :event_ids, event_ids: [], customer_ids: [])
    end
end
