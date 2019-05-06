class ConfirmationsController < Devise::ConfirmationsController
  def show
    super do |resource|
      sign_in(resource)
#      flash[:alert] = "Please update your password."
    end
  end
  
  private

  def after_confirmation_path_for(resource_name, resource)
    if current_user.temporary_password.blank?
      root_path
    else
      edit_user_registration_path(current_user)
    end
  end
end