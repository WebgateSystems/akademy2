class StudentDashboardController < ApplicationController
  before_action :require_student!

  helper_method :can_access_management?

  def index
    # Check if there's a token to auto-fill
    @join_token = params[:token]

    @school = current_user.school
    @classes = current_user.school_classes.where(
      id: StudentClassEnrollment.where(student: current_user, status: 'approved').select(:school_class_id)
    ).order(:name)
    @current_class = @classes.first

    # Get pending enrollments for the empty state
    @pending_enrollments = current_user.student_class_enrollments
                                       .where(status: 'pending')
                                       .includes(school_class: :school)

    # Preload awaiting counts for sidebar (avoid N+1) - empty for students
    @classes.pluck(:id)
    @classes_awaiting_counts = {}

    @subjects = Subject.where(school_id: [nil, @school&.id])
                       .includes(units: :learning_modules)
                       .order(:order_index)

    # Load student's own results (always load if student has approved classes)
    load_student_results_for_current_user if @classes.any?

    render 'student_dashboard/index'
  end

  # GET /join/class/:token
  # Redirect to student dashboard with token pre-filled
  def join_class
    token = params[:token]

    # Store the token in session for after login
    session[:join_class_token] = token

    redirect_to public_home_path(token: token)
  end

  private

  def require_student!
    return if user_signed_in? && current_user.student?

    # Store intended destination for after login
    store_location_for(:user, request.fullpath)

    # Redirect to login with student role
    # rubocop:disable I18n/GetText/DecorateString
    redirect_to new_user_session_path(role: 'student'),
                alert: 'Zaloguj się jako uczeń, aby uzyskać dostęp do panelu ucznia.'
    # rubocop:enable I18n/GetText/DecorateString
  end

  def load_student_results_for_current_user
    @subjects = Subject.where(school_id: [nil, @school&.id])
                       .includes(units: :learning_modules)
                       .order(:order_index)

    @subject_results = {}

    @subjects.each do |subject|
      result = calculate_subject_result(subject)
      @subject_results[subject.id] = result if result
    end
  end

  def calculate_subject_result(subject)
    module_ids = subject.units.flat_map { |u| u.learning_modules.pluck(:id) }
    return nil if module_ids.empty?

    quiz_results = QuizResult.where(user_id: current_user.id, learning_module_id: module_ids)
    total_modules = module_ids.count
    completed = quiz_results.count
    average_score = quiz_results.average(:score)&.round || 0

    {
      total_modules: total_modules,
      completed: completed,
      completion_rate: total_modules.positive? ? ((completed.to_f / total_modules) * 100).round : 0,
      average_score: average_score,
      quiz_results: quiz_results.includes(:learning_module).order(created_at: :desc)
    }
  end

  def can_access_management?
    return false unless current_user

    user_roles = current_user.roles.pluck(:key)
    user_roles.include?('principal') || user_roles.include?('school_manager')
  end
end
