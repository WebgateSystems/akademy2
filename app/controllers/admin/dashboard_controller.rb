class Admin::DashboardController < Admin::BaseController
  def index
    @resources = Admin::ResourcesController::RESOURCES
  end
end
