class AccountTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account_type, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource
  
  # GET /account_types
  # GET /account_types.json
  def index
#    @account_types = AccountType.all
    @account_types = current_user.super? ? AccountType.all : current_user.company.account_types
  end

  # GET /account_types/1
  # GET /account_types/1.json
  def show
    @accounts = @account_type.accounts.page(params[:page]).per(20)
  end

  # GET /account_types/new
  def new
    @account_type = AccountType.new
  end

  # GET /account_types/1/edit
  def edit
  end

  # POST /account_types
  # POST /account_types.json
  def create
    @account_type = AccountType.new(account_type_params)
    respond_to do |format|
      if @account_type.save
        format.html { redirect_to account_types_path, notice: 'AccountType was successfully created.' }
        format.html { redirect_to :back, notice: 'Wallet Type was successfully created.' }
      else
        format.html { render :new }
        format.json { render json: @account_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account_types/1
  # PATCH/PUT /account_types/1.json
  def update
    respond_to do |format|
      if @account_type.update(account_type_params)
        format.html { redirect_to account_types_path, notice: 'Wallet Type was successfully updated.' }
        format.json { render :show, status: :ok, location: @account_type }
      else
        flash[:notice] = "Error"
        format.html { render :edit }
        format.json { render json: @account_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account_types/1
  # DELETE /account_types/1.json
  def destroy
    @account_type.destroy
    respond_to do |format|
      format.html { redirect_to account_types_path, notice: 'Wallet Type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_account_type
      @account_type = AccountType.find_by(AccountTypeID: params[:id], CompanyNumber: params[:company_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def account_type_params
      params.fetch(:account_type, {}).permit(:AccountTypeDesc, :CompanyNumber, :CanFundByACH, :CanFundByCC, :CanFundByCash, :CanWithdraw, 
        :WithdrawAll, :CanPull, :CanRequestPmtBySearch, :CanRequestPmtByScan, :CanSendPmt, :CanBePulledBySearch, :CanBePulledByScan, :CanBePushedByScan, 
        :MinMaintainBal, :contract_id, :date_of_birth_required, :social_security_number_required, :DefaultMinBal)
    end
    
end
