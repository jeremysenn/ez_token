class CustomersController < ApplicationController
  before_action :authenticate_user!, except: [:qr_code]
  before_action :set_customer, only: [:show, :edit, :update, :destroy, :one_time_payment, :send_barcode_link_sms_message, :barcode, :create_account_and_add_to_event]
  load_and_authorize_resource :except => [:find_by_barcode]
#  skip_load_resource only: [:barcode]
  skip_load_resource only: [:find_by_barcode, :qr_code]
  
  helper_method :customers_sort_column, :customers_sort_direction
  
  # GET /customers
  # GET /customers.json
  def index
#    @group_id = params[:group_id] ||= 18
#    @group_id = params[:group_id] ||= (current_user.caddy_admin?) ? 13 : (current_user.event_admin? ? 16 : 18)
    unless params[:q].blank?
      @query_string = "%#{params[:q]}%"
      if customers_sort_column == "accounts.Balance"
#        @all_customers = current_user.company.customers_by_user_role(current_user).where(GroupID: @group_id).where("NameF like ? OR NameL like ? OR PhoneMobile like ?", @query_string, @query_string, @query_string).joins(:accounts).order("#{customers_sort_column} #{customers_sort_direction}")
        @all_customers = current_user.company.customers.where("NameF like ? OR NameL like ? OR PhoneMobile like ?", @query_string, @query_string, @query_string).joins(:accounts).order("#{customers_sort_column} #{customers_sort_direction}")
      else
#        @all_customers = current_user.company.customers_by_user_role(current_user).where(GroupID: @group_id).where("NameF like ? OR NameL like ? OR PhoneMobile like ?", @query_string, @query_string, @query_string).order("#{customers_sort_column} #{customers_sort_direction}")
        @all_customers = current_user.company.customers.where("NameF like ? OR NameL like ? OR PhoneMobile like ?", @query_string, @query_string, @query_string).joins(:accounts).order("#{customers_sort_column} #{customers_sort_direction}")
      end
    else
      if customers_sort_column == "accounts.Balance"
#        @all_customers = current_user.company.customers_by_user_role(current_user).where(GroupID: @group_id).joins(:accounts).order("#{customers_sort_column} #{customers_sort_direction}")
        @all_customers = current_user.company.customers.joins(:accounts).order("#{customers_sort_column} #{customers_sort_direction}")
      else
#        @all_customers = current_user.company.customers_by_user_role(current_user).where(GroupID: @group_id).order("#{customers_sort_column} #{customers_sort_direction}")
        @all_customers = current_user.company.customers.order("#{customers_sort_column} #{customers_sort_direction}")
      end
    end
    
#    @type = params[:type] ||= 'Regular'
#    unless params[:q].blank?
#      @query_string = "%#{params[:q]}%"
#      if customers_sort_column == "accounts.Balance"
#        unless @type == "Anonymous"
#          @all_customers = current_user.company.customers.not_anonymous.where("NameF like ? OR NameL like ? OR PhoneMobile like ?", @query_string, @query_string, @query_string).joins(:accounts).order("#{customers_sort_column} #{customers_sort_direction}")
#        else
#          @all_customers = current_user.company.customers.anonymous.where("NameF like ? OR NameL like ? OR PhoneMobile like ?", @query_string, @query_string, @query_string).joins(:accounts).order("#{customers_sort_column} #{customers_sort_direction}")
#        end
#      else
#        unless @type == "Anonymous"
#          @all_customers = current_user.company.customers.not_anonymous.where("NameF like ? OR NameL like ? OR PhoneMobile like ?", @query_string, @query_string, @query_string).order("#{customers_sort_column} #{customers_sort_direction}") #.order("customer.NameL")
#        else
#          @all_customers = current_user.company.customers.anonymous.where("NameF like ? OR NameL like ? OR PhoneMobile like ?", @query_string, @query_string, @query_string).order("#{customers_sort_column} #{customers_sort_direction}") #.order("customer.NameL")
#        end
#      end
#    else
#      if customers_sort_column == "accounts.Balance"
#        unless @type == "Anonymous"
#          @all_customers = current_user.company.customers.not_anonymous.joins(:accounts).order("#{customers_sort_column} #{customers_sort_direction}")
#        else
#          @all_customers = current_user.company.customers.anonymous.joins(:accounts).order("#{customers_sort_column} #{customers_sort_direction}")
#        end
#      else
#        unless @type == "Anonymous"
#          @all_customers = current_user.company.customers.not_anonymous.order("#{customers_sort_column} #{customers_sort_direction}")
#        else
#          @all_customers = current_user.company.customers.anonymous.order("#{customers_sort_column} #{customers_sort_direction}")
#        end
#      end
#    end

    @customers = @all_customers.page(params[:page]).per(20)
    respond_to do |format|
      format.html {}
      format.csv { 
        send_data @all_customers.to_csv, filename: "payees_#{Time.now}.csv" 
        }
    end
  end
  
  # GET /customers/1
  # GET /customers/1.json
  def show
    @accounts = current_user.administrator? ? @customer.accounts.where(CompanyNumber: current_user.company_id) : @customer.accounts
    if params[:account_id].blank?
      @account = @accounts.first
    else
      @account = @accounts.find(params[:account_id])
    end
    unless @account.blank?
#      @withdrawal_transactions = Kaminari.paginate_array(@customer.withdrawals).page(params[:withdrawals]).per(10)
      @withdrawal_transactions = Kaminari.paginate_array(@account.withdrawals).page(params[:withdrawals]).per(10)
  #    @payment_transactions =  Kaminari.paginate_array(@customer.successful_payments).page(params[:payments]).per(10)
      @payment_transactions =  Kaminari.paginate_array(@account.successful_wire_transactions.sort_by(&:date_time).reverse).page(params[:payments]).per(10)
      @check_transactions =  Kaminari.paginate_array(@customer.cashed_checks).page(params[:checks]).per(10)
      @sms_messages = @customer.sms_messages.order("created_at DESC").page(params[:messages]).per(10)
  #    @events = @customer.events
      @events = @account.events
      if params[:event_id].blank?
        @event = @events.first
      else
        @event = @events.find(params[:event_id])
      end
    end
    if @customer.user.blank?
      @temporary_password = SecureRandom.random_number(10**6).to_s
    end
  end
  
  # GET /customers/new
  def new
    @customer = Customer.new
    @customer.accounts.build
  end
  
  # GET /customers/1/edit
  def edit
  end
  
  # POST /customers
  # POST /customers.json
  def create
    @customer = Customer.new(customer_params)

    respond_to do |format|
      if @customer.save
        format.html { redirect_to @customer, notice: "Customer account was successfully created." }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to @customer, notice: 'Customer account was successfully updated.' }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy
    user = @customer.user
    @customer.destroy
    user.destroy unless user.blank?
    respond_to do |format|
      format.html { redirect_to customers_url, notice: 'Customer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def one_time_payment
    amount = params[:amount].to_f.abs unless params[:amount].blank?
    note = params[:note]
    receipt_number = params[:receipt_number]
    if params[:pay_and_text]
      response = @customer.one_time_payment(amount, note, receipt_number)
    else
      response = @customer.one_time_payment_with_no_text_message(amount, note, receipt_number)
    end
#    transaction_id = @customer.one_time_payment(amount, note)
    response_code = response[:return]
    unless response_code.to_i > 0
      transaction_id = response[:tran_id]
#      @customer.generate_barcode_access_string
    else
      error_code = response_code
    end
    Rails.logger.debug "*********************************One time payment transaction ID: #{transaction_id}"
    unless transaction_id.blank?
      redirect_back fallback_location: @customer, notice: 'One time payment submitted.'
    else
      redirect_back fallback_location: @customer, alert: "There was a problem creating the one time payment. Error code: #{ErrorDesc.find_by(error_code: error_code)}"
    end
  end
  
  def send_sms_message
    @message_body = params[:message_body]
    unless params[:customer_ids].blank?
      params[:customer_ids].each do |customer_id|
        customer = Customer.where(CustomerID: customer_id).first
        customer.send_sms_message(@message_body, current_user.id) unless customer.blank?
      end
      redirect_back fallback_location: customers_path, notice: 'Text message sent.'
    else
      redirect_back fallback_location: customers_path, alert: 'You must select at least one customer to text message.'
    end
  end
  
  def barcode
#    @customer = Customer.find_by(barcode_access_string: params[:id]) # ID is random and unique urlsafe_base64 string
#    if current_user.customer == @customer
#      unless @customer.blank?
#        @base64_barcode_string = Transaction.ezcash_get_barcode_png_web_service_call(@customer.CustomerID, current_user.company_id, 5)
#      else
#        redirect_to root_path, alert: 'There was a problem getting barcode.'
#      end
#    else
#      redirect_back fallback_location: root_path, alert: 'Only the payee has access to that page.'
#    end
    respond_to do |format|
      format.html {
        unless @customer.blank?
#          @base64_barcode_string = Transaction.ezcash_get_barcode_png_web_service_call(@customer.CustomerID, current_user.company_id, 5)
          @base64_barcode_string = @customer.barcode_png
        else
          redirect_to root_path, alert: 'There was a problem getting barcode.'
        end
      }
      format.json{
        unless @customer.blank?
          if params[:company_id].blank?
            if params[:amount].blank?
              @base64_barcode_string = @customer.barcode_png
            else
              @base64_barcode_string = @customer.barcode_png_with_amount(params[:amount])
            end
          else
            if params[:amount].blank?
              @base64_barcode_string = @customer.barcode_png_by_company(params[:company_id])
            else
              @base64_barcode_string = @customer.barcode_png_with_amount_by_company(params[:amount], params[:company_id])
            end
          end
#          @base64_barcode_string = Transaction.ezcash_get_barcode_png_web_service_call(@customer.CustomerID, params[:company_id].blank? ? current_user.company_id : params[:company_id], 5)
          render json: {"barcode_string" => @base64_barcode_string}
        else
          render json: { error: ["Error: Problem generating QR Code."] }, status: :unprocessable_entity
        end
      }
    end
  end
  
  def send_barcode_link_sms_message
    unless @customer.barcode_access_string.blank?
      @customer.send_barcode_link_sms_message
      redirect_back fallback_location: @customer, notice: 'Text message sent.'
    else
      redirect_back fallback_location: @customer, alert: 'There was a problem with barcode.'
    end
  end
  
  def send_barcode_sms_message
    amount = params[:withdrawal_amount]
    account_id = params[:account_id]
    unless account_id.blank?
      @customer.send_barcode_sms_message(account_id, amount.blank? ? 0 : amount)
      redirect_back fallback_location: @customer, notice: 'QR Code sent to phone.'
    else
      redirect_back fallback_location: @customer, notice: 'There was a problem sending the QR Code to phone.'
    end
  end
  
  # GET /customers/123456789/find_by_barcode
  def find_by_barcode
    company_id = params[:company_id]
    @event = Event.find(params[:event_id])
    unless company_id.blank?
      @barcode = CustomerBarcode.where(:Barcode => params[:id], :CompanyNumber => current_user.company_id).first
    else
      @barcode = CustomerBarcode.where(:Barcode => params[:id]).first
    end
    unless @barcode.blank?
      @customer = @barcode.customer
    else
      @customer = Customer.find_by(barcode_access_string: params[:id])
    end
    unless @customer.blank?
      unless @event.blank?
        if @customer.events.include?(@event)
          @account = @customer.events.find(@event.id).account
        end
      else
        @account = @customer.accounts.where(CompanyNumber: company_id).first
      end
    end
    respond_to do |format|
      unless @customer.blank? or @account.blank?
        format.json {render json: {"first_name" => @customer.first_name, "last_name" => @customer.last_name, "balance" => @account.available_balance, "account_id" => @account.id, "customer_barcode_id" => @barcode.blank? ? nil : @barcode.id} }
      else
        format.json {render json: { error: ["Error: Customer/Account cannot be found."] }, status: :unprocessable_entity}
      end
    end
    
#    respond_to do |format|
#      unless @barcode.blank? or @barcode.used?
#        @customer = @barcode.customer
#        format.json {render json: {"first_name" => @customer.user.first_name, "last_name" => @customer.user.last_name, "balance" => @customer.balance, "account_id" => @customer.account.id, "customer_barcode_id" => @barcode.id} }
#      else
#        format.json {render json: { error: ["Error: Customer cannot be found or QR Code has already been used."] }, status: :unprocessable_entity}
#      end
#    end
  end
  
  # GET /customers/123456789/qr_code
  def qr_code
    @customer = Customer.find_by(barcode_access_string: params[:id])
    @user = @customer.user
    unless @customer.blank? or @user.blank?
      send_data @user.qr_code_png, :type => 'image/png',:disposition => 'inline'
    end
  end
  
  # GET /customers/1/create_account_and_add_to_event
  def create_account_and_add_to_event
    @event = Event.find(params[:event_id])
#    @account = Account.create(CustomerID: @customer.id, CompanyNumber: current_user.company_id, Balance: 0, MinBalance: 0, ActTypeID: 6)
#    @event.accounts << @account
    respond_to do |format|
      format.json {render json: {}, status: :ok}
    end
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = Customer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      params.require(:customer).permit(:ParentCustID, :CompanyNumber, :Active, :GroupID, :NameF, :NameL, :NameS, :PhoneMobile, :Email, 
        :LangID, :Registration_Source, :Registration_Source_ext, :create_payee_user_flag, :create_basic_user_flag, :create_caddy_user_flag, :avatar, :avatar_cache, :SSN,
        accounts_attributes:[:CompanyNumber, :Balance, :MinBalance, :Active, :CustomerID, :ActNbr, :ActTypeID, :BankActNbr, :RoutingNbr, 
          :AddGroupID, :AbleToDelete, :_destroy,:id, :event_ids, event_ids: []])
    end
    
    ### Secure the customeres sort direction ###
    def customers_sort_direction
      %w[asc desc].include?(params[:customers_direction]) ?  params[:customers_direction] : (params[:type] == 'Anonymous' ? "desc" :  "asc")
    end

    ### Secure the customers sort column name ###
    def customers_sort_column
      ["customer.NameL", "customer.NameF", "customer.PhoneMobile", "accounts.Balance", "customer.CreateDate"].include?(params[:customers_column]) ? params[:customers_column] : (params[:type] == 'Anonymous' ? "customer.CreateDate" : "customer.NameF")
    end
  
end
