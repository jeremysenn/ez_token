class UsersController < ApplicationController
  before_action :authenticate_user!, except: :forgot_password
  before_action :set_user, only: [:show, :edit, :update, :destroy, :pin_verification, :verify_phone, :confirm]
  load_and_authorize_resource


  # GET /users
  # GET /users.json
  def index
    if current_user.super?
      @company_id = params[:company_id].blank? ? Company.all.map{|c| c.CompanyNumber} : params[:company_id] 
      @role = params[:role].blank? ? ['admin', 'basic', 'collaborator'] : params[:role] 
      unless params[:q].blank?
        @query_string = "%#{params[:q]}%"
        users = User.where(company_id: @company_id, role: @role).where("first_name like ? OR last_name like ? OR phone like ? OR email like ?", @query_string, @query_string, @query_string, @query_string)
      else
        users = User.where(company_id: @company_id, role: @role)
      end
      @users = users.page(params[:page]).per(20)
    elsif current_user.can_view_users?
      users = current_user.company.users
      @users = users.page(params[:page]).per(20)
    else
      redirect_back fallback_location: root_path, notice: 'You are not authorized.'
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    if current_user.can_view_users?
      @devices = @user.devices
      @admin_events = @user.admin_events
    else
      redirect_back fallback_location: root_path, notice: 'You are not authorized.'
    end
  end

  # GET /users/new
  def new
    if current_user.can_edit_users?
      @user = User.new
    else
      redirect_back fallback_location: root_path, notice: 'You are not authorized.'
    end
  end

  # GET /users/1/edit
  def edit
    unless current_user.can_edit_users?
      redirect_back fallback_location: root_path, notice: 'You are not authorized.'
    end
  end

  # POST /users
  # POST /users.json
  def create
    if current_user.can_edit_users?
      @user = User.new(user_params)
      temporary_password = SecureRandom.random_number(10**6).to_s
      @user.temporary_password = temporary_password
      @user.password = temporary_password
      @user.password_confirmation = temporary_password
      respond_to do |format|
        if @user.save
#          format.html { redirect_to users_admin_path(@user), notice: 'User was successfully created.' }
          format.html { redirect_to users_admin_index_path, notice: 'User was successfully created.' }
          format.json { render :show, status: :created, location: @user }
        else
          format.html { render :new }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_back fallback_location: root_path, notice: 'You are not authorized.'
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    if current_user.can_edit_users?
      respond_to do |format|
        if @user.update(user_params)
#          format.html { redirect_to users_admin_path(@user), notice: 'User was successfully updated.' }
          format.html { redirect_to users_admin_index_path, notice: 'User was successfully updated.' }
          format.json { render :show, status: :ok, location: @user }
        else
          format.html { render :edit }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_back fallback_location: root_path, notice: 'You are not authorized.'
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def forgot_password
    @user = User.find_by(phone: params[:phone])
    unless @user.blank?
#      @user.send_reset_password_instructions
      @user.send_reset_password_instructions_text_message
    end
    redirect_to new_user_session_path, notice: 'Forgot password link sent.'
  end
  
  def confirm
    @user.confirmed_at = Time.now
    if @user.save
#      redirect_back fallback_location: root_path, notice: 'Web user successfully confirmed.'
      flash[:notice] = 'Web user successfully confirmed.'
      if @user.basic? and not @user.customer.blank?
        redirect_to customer_path(@user.customer)
      else
        redirect_to users_admin_path(@user)
      end
    else
      redirect_back fallback_location: root_path, notice: 'There was a problem trying to confirm the web user.'
    end
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:first_name, :last_name, :company_id, :email, :password, :time_zone, :admin, :active, 
        :role, :pin, :phone, :time_zone, 
        :view_events, :edit_events, :view_wallet_types, :edit_wallet_types, :view_accounts, :edit_accounts, :view_users, :edit_users, :view_atms, :can_quick_pay,
        device_ids: [], admin_event_ids: [])
    end
    
end
