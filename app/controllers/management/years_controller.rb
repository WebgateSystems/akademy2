# frozen_string_literal: true

module Management
  class YearsController < Management::BaseController
    def index
      @school = current_school_manager.school
      redirect_to management_root_path, alert: 'Brak przypisanej szkoły' unless @school

      @academic_years = AcademicYear.where(school: @school).ordered
      @current_academic_year_record = @school&.current_academic_year
    end
  end
end
