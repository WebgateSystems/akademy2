class HomeController < ApplicationController
  layout 'landing'

  helper_method :can_access_management?

  def index
    # If user is signed in and is a student, show student dashboard
    if user_signed_in? && current_user.student?
      render_student_dashboard
    else
      # Show landing page for everyone else
      render 'home/index'
    end
  end

  private

  def render_student_dashboard
    @school = current_user.school
    @classes = current_user.school_classes.order(:name)
    @current_class = @classes.first

    # Preload awaiting counts for sidebar (avoid N+1) - empty for students
    class_ids = @classes.pluck(:id)
    @classes_awaiting_counts = StudentClassEnrollment.where(school_class_id: class_ids, status: 'pending')
                                                     .group(:school_class_id)
                                                     .count

    @subjects = Subject.where(school_id: [nil, @school&.id])
                       .includes(units: :learning_modules)
                       .order(:order_index)

    # Load student's own results
    load_student_results_for_current_user if @current_class

    # Use application layout (same as DashboardController)
    render 'dashboard/index', layout: 'application'
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
