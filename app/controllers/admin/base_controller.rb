class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin_panel

  layout 'admin'

  private

  def authorize_admin_panel
    authorize :admin, :access?
  end
end


