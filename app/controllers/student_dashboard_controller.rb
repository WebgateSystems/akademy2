class StudentDashboardController < ApplicationController
  before_action :require_student!
  before_action :load_common_data
  before_action :load_learning_module, only: %i[learning_module quiz submit_quiz result]

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

  # GET /home/subjects/:id
  # Show subject with all modules (or redirect if single module)
  def subject
    # Find by slug or id
    @subject = Subject.where(school_id: [nil, @school&.id])
                      .includes(units: { learning_modules: :contents })
                      .find_by(slug: params[:id]) ||
               Subject.where(school_id: [nil, @school&.id])
                      .includes(units: { learning_modules: :contents })
                      .find_by(id: params[:id])

    unless @subject
      redirect_to public_home_path, alert: I18n.t('student_dashboard.alerts.subject_not_found')
      return
    end

    # Get all published modules for this subject
    all_modules = @subject.units.flat_map { |u| u.learning_modules.where(published: true).to_a }

    # If only one module, redirect directly to it
    return redirect_to student_module_path(all_modules.first) if all_modules.count == 1

    @units = @subject.units.order(:order_index)
    @module_results = QuizResult.where(
      user_id: current_user.id,
      learning_module_id: all_modules.map(&:id)
    ).index_by(&:learning_module_id)

    render 'student_dashboard/subject'
  end

  # GET /home/modules/:id
  # Show learning module with video/infographic content
  def learning_module
    @contents = @learning_module.contents.order(:order_index)
    @video_contents = @contents.where(content_type: 'video')
    @infographic_contents = @contents.where(content_type: 'infographic')

    # Log content access
    EventLogger.log_content_access(content: @contents.first, user: current_user, action: 'view') if @contents.any?

    render 'student_dashboard/learning_module'
  end

  # GET /home/modules/:id/quiz
  # Show quiz for the module
  def quiz
    @quiz_content = @learning_module.contents.find_by(content_type: 'quiz')
    @questions = @quiz_content&.payload&.dig('questions') || []
    @previous_result = QuizResult.find_by(user_id: current_user.id, learning_module_id: @learning_module.id)

    # Log quiz start
    EventLogger.log_quiz_start(quiz: @learning_module, user: current_user)

    render 'student_dashboard/quiz'
  end

  # POST /home/modules/:id/quiz
  # Submit quiz answers
  def submit_quiz
    answers = params[:answers] || {}
    @quiz_content = @learning_module.contents.find_by(content_type: 'quiz')
    questions = @quiz_content&.payload&.dig('questions') || []

    # Calculate score
    correct_count = 0
    questions.each_with_index do |question, index|
      user_answer = answers[index.to_s]
      next if user_answer.blank? # Skip unanswered questions

      user_answer_index = user_answer.to_i
      options = question['options'] || []
      correct_ids = question['correct'] || []

      # Get the option id that user selected
      selected_option = options[user_answer_index]
      next unless selected_option

      selected_id = selected_option['id']
      is_correct = correct_ids.include?(selected_id)

      Rails.logger.info "[QUIZ] Q#{index}: idx=#{user_answer_index}, sel=#{selected_id}, " \
                        "correct=#{correct_ids}, ok=#{is_correct}"

      correct_count += 1 if is_correct
    end

    score = questions.any? ? ((correct_count.to_f / questions.count) * 100).round : 0
    passed = score >= 80

    # Save result - always save current attempt
    @quiz_result = QuizResult.find_or_initialize_by(
      user_id: current_user.id,
      learning_module_id: @learning_module.id
    )

    # Store best score separately, but always save current attempt details
    best_score = [@quiz_result.score || 0, score].max
    best_passed = best_score >= 80

    @quiz_result.update!(
      score: best_score,
      passed: best_passed,
      details: {
        answers: answers,
        correct_count: correct_count,
        total: questions.count,
        last_score: score,
        last_passed: passed
      },
      completed_at: Time.current
    )

    # Log completion with current attempt score
    EventLogger.log_quiz_complete(quiz_result: @quiz_result, user: current_user)

    # Pass current attempt result to the result page
    redirect_to student_result_path(@learning_module, score: score, passed: passed)
  end

  # GET /home/modules/:id/result
  # Show quiz result
  def result
    @quiz_result = QuizResult.find_by(user_id: current_user.id, learning_module_id: @learning_module.id)
    return redirect_to student_quiz_path(@learning_module) unless @quiz_result

    # Use current attempt score if passed via params, otherwise use best score from DB
    @current_score = params[:score].present? ? params[:score].to_i : @quiz_result.score
    @current_passed = params[:passed].present? ? params[:passed] == 'true' : @quiz_result.passed
    @best_score = @quiz_result.score

    render 'student_dashboard/result'
  end

  private

  def require_student!
    return if user_signed_in? && current_user.student?

    # If user is logged in but not a student, sign them out first
    if user_signed_in?
      sign_out(current_user)
      session.delete(:return_to)
      session.delete(:user_return_to)
    end

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

  def load_common_data
    @school = current_user.school
    @classes = current_user.school_classes.where(
      id: StudentClassEnrollment.where(student: current_user, status: 'approved').select(:school_class_id)
    ).order(:name)
  end

  def load_learning_module
    # Find by slug or id
    @learning_module = LearningModule.includes(unit: :subject).find_by(slug: params[:id]) ||
                       LearningModule.includes(unit: :subject).find_by(id: params[:id])

    unless @learning_module
      redirect_to public_home_path, alert: I18n.t('student_dashboard.alerts.module_not_found')
      return
    end

    @subject = @learning_module.unit.subject

    # Verify access
    return if @subject.school_id.nil? || @subject.school_id == current_user.school_id

    redirect_to public_home_path, alert: I18n.t('student_dashboard.alerts.access_denied')
  end
end
