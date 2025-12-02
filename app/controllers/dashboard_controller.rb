class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher!
  before_action :set_notifications_count
  before_action :set_dashboard_token

  helper_method :can_access_management?
  helper_method :notifications_count

  def index
    @school = current_user.school
    @classes = current_user.assigned_classes
                           .where(school_id: @school&.id)
                           .order(:name)

    # Preload awaiting counts for sidebar (avoid N+1)
    class_ids = @classes.pluck(:id)
    @classes_awaiting_counts = StudentClassEnrollment.where(school_class_id: class_ids, status: 'pending')
                                                     .group(:school_class_id)
                                                     .count

    # Select class from param or default to first
    @current_class = if params[:class_id].present?
                       @classes.find_by(id: params[:class_id]) || @classes.first
                     else
                       @classes.first
                     end

    @subjects = Subject.where(school_id: [nil, @school&.id])
                       .includes(units: :learning_modules)
                       .order(:order_index)

    load_class_statistics if @current_class
  end

  def quiz_results
    @school = current_user.school
    @classes = current_user.assigned_classes
                           .where(school_id: @school&.id)
                           .order(:name)

    # Preload awaiting counts for sidebar
    class_ids = @classes.pluck(:id)
    @classes_awaiting_counts = StudentClassEnrollment.where(school_class_id: class_ids, status: 'pending')
                                                     .group(:school_class_id)
                                                     .count

    @current_class = if params[:class_id].present?
                       @classes.find_by(id: params[:class_id]) || @classes.first
                     else
                       @classes.first
                     end

    @subject = Subject.find(params[:subject_id])
    load_quiz_results_data
  end

  def students
    @school = current_user.school
    @classes = current_user.assigned_classes
                           .where(school_id: @school&.id)
                           .order(:name)

    class_ids = @classes.pluck(:id)
    @classes_awaiting_counts = StudentClassEnrollment.where(school_class_id: class_ids, status: 'pending')
                                                     .group(:school_class_id)
                                                     .count

    @current_class = if params[:class_id].present?
                       @classes.find_by(id: params[:class_id]) || @classes.first
                     else
                       @classes.first
                     end

    return unless @current_class

    # Load enrollments first (used in view)
    @enrollments = @current_class.student_class_enrollments.index_by(&:student_id)

    # Load students without includes - we use @enrollments hash
    @students = @current_class.students.order(:last_name, :first_name)
  end

  def notifications
    @school = current_user.school
    @classes = current_user.assigned_classes
                           .where(school_id: @school&.id)
                           .order(:name)

    class_ids = @classes.pluck(:id)
    @classes_awaiting_counts = StudentClassEnrollment.where(school_class_id: class_ids, status: 'pending')
                                                     .group(:school_class_id)
                                                     .count

    @notifications_list = Notification.for_school(@school)
                                      .for_role('teacher')
                                      .unresolved
                                      .order(created_at: :desc)
                                      .limit(50)
  end

  def show_student
    @school = current_user.school
    @classes = current_user.assigned_classes
                           .where(school_id: @school&.id)
                           .order(:name)

    class_ids = @classes.pluck(:id)
    @classes_awaiting_counts = StudentClassEnrollment.where(school_class_id: class_ids, status: 'pending')
                                                     .group(:school_class_id)
                                                     .count

    @student = User.find(params[:id])

    # Verify teacher has access to this student
    unless student_in_teacher_classes?(@student)
      redirect_to dashboard_students_path, alert: 'Brak dostępu do tego ucznia'
      return
    end

    @current_class = @student.student_class_enrollments
                             .joins(:school_class)
                             .where(school_class_id: class_ids)
                             .first&.school_class

    load_student_results
  end

  private

  def student_in_teacher_classes?(student)
    teacher_class_ids = current_user.teacher_class_assignments.pluck(:school_class_id)
    student.student_class_enrollments.exists?(school_class_id: teacher_class_ids)
  end

  def load_student_results
    @subjects = Subject.where(school_id: [nil, @school&.id])
                       .includes(units: :learning_modules)
                       .order(:order_index)

    @subject_results = {}

    @subjects.each do |subject|
      module_ids = subject.units.flat_map { |u| u.learning_modules.pluck(:id) }
      next if module_ids.empty?

      quiz_results = QuizResult.where(user_id: @student.id, learning_module_id: module_ids)

      total_modules = module_ids.count
      completed = quiz_results.count
      average_score = quiz_results.average(:score)&.round || 0

      @subject_results[subject.id] = {
        total_modules: total_modules,
        completed: completed,
        completion_rate: total_modules.positive? ? ((completed.to_f / total_modules) * 100).round : 0,
        average_score: average_score,
        quiz_results: quiz_results.includes(:learning_module).order(created_at: :desc)
      }
    end
  end

  def require_teacher!
    return if current_user.teacher?

    # Store the location user was trying to access (if not already stored)
    session[:return_to] = request.fullpath if request.get? && session[:return_to].blank?

    # Redirect to login instead of root_path to avoid redirect loop
    # rubocop:disable I18n/GetText/DecorateString
    redirect_to new_user_session_path, alert: 'Dostęp tylko dla nauczycieli. Zaloguj się ponownie.'
    # rubocop:enable I18n/GetText/DecorateString
  end

  def can_access_management?
    return false unless current_user

    user_roles = current_user.roles.pluck(:key)
    user_roles.include?('principal') || user_roles.include?('school_manager')
  end

  def set_notifications_count
    @notifications_count = notifications_count
  end

  def notifications_count
    school = current_user&.school
    return 0 unless school

    # Count unread notifications for teacher role
    # Including: student_awaiting_approval and quiz_completed
    Notification.for_school(school)
                .for_role('teacher')
                .where(notification_type: %w[student_awaiting_approval quiz_completed])
                .unread
                .unresolved
                .count
  end

  def set_dashboard_token
    return unless current_user

    @dashboard_token = Jwt::TokenService.encode({ user_id: current_user.id })
  end

  def load_class_statistics
    @students_count = @current_class.students.count
    @students_awaiting = @current_class.student_class_enrollments.where(status: 'pending').count

    # Videos watched by students in this class
    student_ids = @current_class.students.pluck(:id)
    @videos_count = Event.where(event_type: 'video_view', user_id: student_ids)
                         .select(:user_id).distinct.count

    # Subject completion rates
    @subject_stats = calculate_subject_stats(student_ids)
  end

  def calculate_subject_stats(student_ids)
    return {} if student_ids.empty?

    stats = {}
    @subjects.each do |subject|
      module_ids = subject.units.flat_map { |u| u.learning_modules.pluck(:id) }
      next if module_ids.empty?

      total_possible = student_ids.count * module_ids.count
      completed = QuizResult.where(user_id: student_ids, learning_module_id: module_ids).count

      stats[subject.id] = {
        completion_rate: total_possible.positive? ? ((completed.to_f / total_possible) * 100).round : 0,
        average_score: QuizResult.where(user_id: student_ids, learning_module_id: module_ids)
                                 .average(:score)&.round || 0
      }
    end
    stats
  end

  def load_quiz_results_data
    return unless @current_class && @subject

    @students = @current_class.students.order(:last_name, :first_name)
    student_ids = @students.pluck(:id)

    # Get learning modules for this subject
    @learning_modules = @subject.units
                                .includes(:learning_modules)
                                .flat_map(&:learning_modules)
                                .sort_by(&:order_index)

    module_ids = @learning_modules.map(&:id)

    # Overall stats
    total_possible = student_ids.count * module_ids.count
    @quiz_results = QuizResult.where(user_id: student_ids, learning_module_id: module_ids)

    completed_count = @quiz_results.count
    @completion_rate = total_possible.positive? ? ((completed_count.to_f / total_possible) * 100).round : 0
    @average_score = @quiz_results.average(:score)&.round || 0

    # Load student answers for the table
    load_student_answers(student_ids)

    # Distribution stats
    calculate_distribution_stats(student_ids)
  end

  def load_student_answers(student_ids)
    @student_answers = {}
    @questions = {}

    # Load quiz contents for this subject's learning modules
    module_ids = @learning_modules.map(&:id)
    quiz_contents = Content.where(learning_module_id: module_ids, content_type: 'quiz')

    # Build questions map from all quizzes (indexed 1-10)
    question_index = 1
    quiz_contents.each do |content|
      next unless content.payload.is_a?(Hash) && content.payload['questions'].is_a?(Array)

      content.payload['questions'].each do |q|
        break if question_index > 10

        correct_option_ids = Array(q['correct'])
        correct_texts = Array(q['options']).select { |opt| correct_option_ids.include?(opt['id']) }
                                           .map { |opt| opt['text'] }

        @questions[question_index] = {
          id: q['id'],
          text: q['text'],
          correct_answer: correct_texts.join(', ')
        }
        question_index += 1
      end
    end

    # Initialize answers for all students
    student_ids.each do |student_id|
      @student_answers[student_id] = {}

      # Get quiz results for this student
      student_results = @quiz_results.select { |r| r.user_id == student_id }

      (1..10).each do |q_num|
        question_data = @questions[q_num]

        if question_data.nil?
          @student_answers[student_id][q_num] = nil
          next
        end

        # Find answer in quiz result details
        answer_found = false
        student_results.each do |result|
          next unless result.details.is_a?(Hash) && result.details['answers'].is_a?(Hash)

          student_answer = result.details['answers'][question_data[:id]]
          next unless student_answer

          correct_ids = find_correct_ids_for_question(question_data[:id], quiz_contents)
          is_correct = Array(student_answer).sort == correct_ids.sort

          answer_text = find_answer_text(question_data[:id], student_answer, quiz_contents)

          @student_answers[student_id][q_num] = {
            correct: is_correct,
            question_text: question_data[:text],
            answer: answer_text
          }
          answer_found = true
          break
        end

        # No answer found for this question
        @student_answers[student_id][q_num] ||= nil
      end
    end
  end

  def find_correct_ids_for_question(question_id, quiz_contents)
    quiz_contents.each do |content|
      next unless content.payload.is_a?(Hash) && content.payload['questions'].is_a?(Array)

      question = content.payload['questions'].find { |q| q['id'] == question_id }
      return Array(question['correct']) if question
    end
    []
  end

  def find_answer_text(question_id, answer_ids, quiz_contents)
    quiz_contents.each do |content|
      next unless content.payload.is_a?(Hash) && content.payload['questions'].is_a?(Array)

      question = content.payload['questions'].find { |q| q['id'] == question_id }
      next unless question

      options = Array(question['options'])
      selected = options.select { |opt| Array(answer_ids).include?(opt['id']) }
      return selected.map { |opt| opt['text'] }.join(', ')
    end
    ''
  end

  def calculate_distribution_stats(student_ids)
    scores_by_student = {}

    student_ids.each do |sid|
      student_scores = @quiz_results.select { |r| r.user_id == sid }.map(&:score)
      scores_by_student[sid] = student_scores.any? ? (student_scores.sum.to_f / student_scores.count).round : nil
    end

    total_students = student_ids.count
    return if total_students.zero?

    no_results = scores_by_student.values.count(&:nil?)
    bad_results = scores_by_student.values.compact.count { |s| s < 50 }
    average_results = scores_by_student.values.compact.count { |s| s >= 50 && s < 75 }
    great_results = scores_by_student.values.compact.count { |s| s >= 75 }

    @distribution = {
      no_results: ((no_results.to_f / total_students) * 100).round,
      bad_results: ((bad_results.to_f / total_students) * 100).round,
      average_results: ((average_results.to_f / total_students) * 100).round,
      great_results: ((great_results.to_f / total_students) * 100).round
    }
  end
end
