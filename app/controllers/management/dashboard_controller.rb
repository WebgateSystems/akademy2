# frozen_string_literal: true

module Management
  class DashboardController < Management::BaseController
    def index
      @school = current_school_manager.school
      return redirect_to authenticated_root_path, alert: 'Brak przypisanej szkoły' unless @school

      load_statistics
      load_school_info
    end

    private

    def load_statistics
      # Count teachers for this school (including awaiting confirmation)
      @teachers_count = User.joins(:user_roles)
                            .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                            .where(user_roles: { school_id: @school.id }, roles: { key: 'teacher' })
                            .distinct
                            .count

      @teachers_awaiting = User.joins(:user_roles)
                               .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                               .where(user_roles: { school_id: @school.id }, roles: { key: 'teacher' })
                               .where(confirmed_at: nil)
                               .distinct
                               .count

      # Count students for this school
      @students_count = User.joins(:user_roles)
                            .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                            .where(user_roles: { school_id: @school.id }, roles: { key: 'student' })
                            .distinct
                            .count

      @students_awaiting = User.joins(:user_roles)
                               .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                               .where(user_roles: { school_id: @school.id }, roles: { key: 'student' })
                               .where(confirmed_at: nil)
                               .distinct
                               .count
    end

    def load_school_info
      # Find headmaster (principal) for this school
      @headmaster = User.joins(:user_roles)
                        .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                        .where(user_roles: { school_id: @school.id }, roles: { key: 'principal' })
                        .first

      # Find deputy headmaster (school_manager) for this school
      @deputy_headmaster = User.joins(:user_roles)
                               .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                               .where(user_roles: { school_id: @school.id }, roles: { key: 'school_manager' })
                               .first
    end
  end
end
