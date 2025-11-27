# frozen_string_literal: true

module Management
  class StudentsController < Management::BaseController
    CURRENT_ACADEMIC_YEAR = '2025/2026'

    def index
      @school = current_school_manager.school
      redirect_to management_root_path, alert: 'Brak przypisanej szkoły' unless @school

      # Load classes for current academic year for dropdown
      @school_classes = SchoolClass.where(school: @school, year: CURRENT_ACADEMIC_YEAR).order(:name)
    end
  end
end
