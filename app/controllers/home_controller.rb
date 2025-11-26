class HomeController < ApplicationController
  layout 'landing'

  def index
    user_signed_in? ? render('dashboard/index') : render('home/index')
  end
end
