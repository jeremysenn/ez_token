class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource

  # GET /companies
  # GET /companies.json
  def index
    @companies = Company.all if current_user.super?
  end

  # GET /companies/1
  # GET /companies/1.json
  def show
    @transaction_account = @company.transaction_account
    unless @transaction_account.blank?
      @start_date = params[:start_date] ||= Date.today.last_week.to_s
      @end_date = params[:end_date] ||= Date.today.to_s
      @all_payment_transactions = @transaction_account.transactions.transfers.where(date_time: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day).sort_by(&:date_time).reverse
    end
    respond_to do |format|
      format.html {
        @payment_transactions =  Kaminari.paginate_array(@all_payment_transactions).page(params[:page]).per(10) unless @all_payment_transactions.blank?
      }
      format.csv { 
        send_data Transaction.export_to_csv(@all_payment_transactions), filename: "Company_#{@company.id}_payment_transactions-#{@start_date}-#{@end_date}.csv" 
        }
    end
  end

  # GET /companies/new
  def new
    @company = Company.new
  end

  # GET /companies/1/edit
  def edit
    @transaction_account = @company.transaction_account
  end

  # POST /companies
  # POST /companies.json
  def create
    @company = Company.new(company_params)

    respond_to do |format|
      if @company.save
        format.html { redirect_to companies_path, notice: 'Company was successfully created.' }
        format.json { render :show, status: :created, location: @company }
      else
        format.html { render :new }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /companies/1
  # PATCH/PUT /companies/1.json
  def update
    respond_to do |format|
      @transaction_account_minimum_balance = company_params[:transaction_account_minimum_balance]
      if @company.update(company_params)
        format.html { 
          @company.transaction_account.update_attribute(:MinBalance, @transaction_account_minimum_balance) unless @transaction_account_minimum_balance.blank?
          redirect_to @company, notice: 'Company was successfully updated.' 
          }
        format.json { render :show, status: :ok, location: @company }
      else
        format.html { render :edit }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    @company.destroy
    respond_to do |format|
      format.html { redirect_to companies_url, notice: 'Company was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company
      @company = Company.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
#    def company_params
#      params.require(:company).permit(:to, :body, :customer_id, :caddy_id)
#    end
    
    def company_params
      params.fetch(:company, {}).permit(:CompanyName, :TxnActID, :FeeActID, 
        :can_quick_pay, :quick_pay_account_type_id, :transaction_account_minimum_balance, :CashierActID)
    end
end
