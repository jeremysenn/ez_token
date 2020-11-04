class StatusDescController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  
  def index
    @dev_statuses = Kaminari.paginate_array(DevStatus.order("date_time DESC").first(100)).page(params[:dev_statuses_page]).per(20)
  end
  
  def show
#    @dev_status = DevStatus.find(params[:id])
    @dev_status = DevStatus.wsdl_find_first_by_status(params[:id])
  end
  
end
