class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  
  protected
  
  # Permit additional parameters for Devise user
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :phone, :company_id])
  end
  
  # Redirect to a specific page on successful sign in
  def after_sign_in_path_for(resource)
    if current_user.sign_in_count == 1
      flash[:alert] = "Please update your password."
      edit_registration_path(current_user)
    else
      sign_in_url = new_user_session_url
      if request.referer == sign_in_url
        super
      else
        stored_location_for(resource) || request.referer || root_path
      end
    end
  end
end
