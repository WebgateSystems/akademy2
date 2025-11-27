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
    # rubocop:disable I18n/GetText/DecorateString
    redirect_to(request.referer.presence || fallback, alert: 'Brak uprawnień.')
    # rubocop:enable I18n/GetText/DecorateString
  end

  # Redirect after sign in based on user roles
  def after_sign_in_path_for(resource)
    return super unless resource.is_a?(User)

    user_roles = resource.roles.pluck(:key)
    has_management_role = user_roles.include?('principal') || user_roles.include?('school_manager')

    return management_root_path if has_management_role

    authenticated_root_path
  end
end
