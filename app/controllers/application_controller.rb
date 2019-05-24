class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
    
  rescue_from CanCan::AccessDenied do |exception|
    redirect_back fallback_location: root_url, alert: exception.message
  end    
  
  protected
  
  # Permit additional parameters for Devise user
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :temporary_password, :email, :phone, :time_zone])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :phone, :company_id, :role])
  end
  
  # Redirect to a specific page on successful sign in
  def after_sign_in_path_for(resource)
    sign_in_url = new_user_session_url
#    unless not current_user.temporary_password.blank? and current_user.sign_in_count > 1

#    if current_user.temporary_password.blank?
#      if request.referer == sign_in_url or (request.referer and request.referer.include? "reset_password")
#        super
#      else
#        stored_location_for(resource) || request.referer || root_path
#      end
#    else
#      edit_user_registration_path(current_user)
#    end
    
    if request.referer == sign_in_url or (request.referer and request.referer.include? "reset_password")
      super
    else
      stored_location_for(resource) || request.referer || root_path
    end
    
  end
  
end
