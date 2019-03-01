class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy, :pin_verification, :verify_phone]
  load_and_authorize_resource


  # GET /users
  # GET /users.json
  def index
    @users = current_user.company.users
#    @admin_users = @users.where(role: 'admin')
#    @basic_users = @users.where(role: 'basic')
#    @payee_users = @users.where(role: 'payee')
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @devices = @user.devices
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    temporary_password = SecureRandom.random_number(10**6).to_s
    @user.temporary_password = temporary_password
    @user.password = temporary_password
    @user.password_confirmation = temporary_password
    respond_to do |format|
      if @user.save
        format.html { redirect_to users_admin_path(@user), notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to users_admin_path(@user), notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
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
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:first_name, :last_name, :company_id, :email, :password, :time_zone, :admin, :active, 
        :role, :pin, :phone, :time_zone, device_ids: [])
    end
    
end
