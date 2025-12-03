class HomeController < ApplicationController
  layout 'landing'

  def index
    # Landing page - always show home/index
    render 'home/index'
  end
end
