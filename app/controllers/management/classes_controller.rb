# frozen_string_literal: true

module Management
  class ClassesController < Management::BaseController
    def index
      @school = current_school_manager.school
      redirect_to management_root_path, alert: 'Brak przypisanej szkoły' unless @school

      @current_academic_year = current_academic_year
      # Load classes for current academic year
      @current_year_classes = SchoolClass.where(school: @school, year: @current_academic_year).order(:name)
      @academic_years = AcademicYear.where(school: @school).distinct.pluck(:year).sort.reverse
      @teachers = User.joins(:user_roles)
                      .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                      .where(user_roles: { school_id: @school.id }, roles: { key: 'teacher' })
                      .order(:first_name, :last_name)
    end
  end
end
