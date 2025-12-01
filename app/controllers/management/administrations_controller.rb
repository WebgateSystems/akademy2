# frozen_string_literal: true

module Management
  class AdministrationsController < Management::BaseController
    def index
      @school = current_school_manager.school
      redirect_to management_root_path, alert: 'Brak przypisanej szkoły' unless @school
    end
  end
end
