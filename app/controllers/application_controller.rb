class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError do
    fallback = if respond_to?(:admin_root_path)
                 admin_root_path
               else
                 (respond_to?(:new_user_session_path) ? new_user_session_path : 'up')
               end
    redirect_to(request.referer.presence || fallback, alert: 'Brak uprawnień.')
  end
end
