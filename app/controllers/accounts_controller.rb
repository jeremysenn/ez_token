class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [:show, :edit, :update, :destroy, :one_time_payment]
  load_and_authorize_resource

  # GET /accounts
  # GET /accounts.json
  def index
    @active = params[:active] ||= 1
    unless current_user.company.account_types.blank?
#      @type_id = params[:type_id] ||= current_user.company.account_types.first.id
      @type_id = params[:type_id]
    end
    unless current_user.company.events.blank?
      @event_id = params[:event_id] ||= current_user.company.events.first.id
    end
    accounts = @type_id.blank? ? current_user.company.accounts.where(Active: @active) : current_user.company.accounts.where(ActTypeID: @type_id, Active: @active)
    unless params[:q].blank?
      @query_string = "%#{params[:q]}%"
#      @accounts = current_user.company.accounts.where(ActID: @query_string)
      @total_accounts_results = accounts.joins(:events).where(events: {id: @event_id})
      @accounts = @total_accounts_results.joins(:customer).where("customer.NameF like ? OR customer.NameL like ? OR customer.PhoneMobile like ?", @query_string, @query_string, @query_string).order("customer.NameL ASC").page(params[:page]).per(20)
    else
#      @accounts = current_user.company.accounts.where(ActTypeID: @type_id).joins(:events).where(events: {id: @event_id})
      @total_accounts_results = accounts.joins(:events).where(events: {id: @event_id})
      @accounts = @total_accounts_results.joins(:customer).order("customer.NameL ASC").page(params[:page]).per(20)
    end
  end

  # GET /accounts/1
  # GET /accounts/1.json
  def show
    @customer = @account.customer
  end

  # GET /accounts/new
  def new
    @account = Account.new
  end

  # GET /accounts/1/edit
  def edit
    @customer = @account.customer
  end

  # POST /accounts
  # POST /accounts.json
  def create
    @account = Account.new(account_params)

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
      if @account.update(account_params)
#        format.html { redirect_to @account, notice: 'Wallet was successfully updated.' }
        format.html { redirect_to @account.customer, notice: 'Wallet was successfully updated.' }
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
      redirect_back fallback_location: @account.customer, notice: 'One time payment submitted.'
    else
      error_description = ErrorDesc.find_by(error_code: error_code)
      redirect_back fallback_location: root_path, alert: "There was a problem creating the one time payment. Error code: #{error_description.blank? ? 'Unknown' : error_description.long_desc}"
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
        account.customer.twilio_send_sms_message(@message_body, current_user.id) unless account.blank? or account.customer.blank?
      end
      redirect_back fallback_location: accounts_path, notice: 'Text message sent.'
    else
      redirect_back fallback_location: accounts_path, alert: 'You must select at least one account to text message.'
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
      params.require(:account).permit(:Balance, :Active, :MinBalance, :ActTypeID, :AbleToDelete, :MaintainBal, :BankActNbr, :RoutingNbr, 
        :cc_charge_amount, :cc_number, :cc_expiration, :cc_cvc, :event_ids, event_ids: [])
    end
end
