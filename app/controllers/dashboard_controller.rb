class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher!
  before_action :set_notifications_count
  before_action :set_dashboard_token

  helper_method :can_access_management?
  helper_method :notifications_count

  def index
    # Check if there's a token to auto-fill
    @join_token = params[:token]

    @school = current_user.school

    # Get pending enrollments for the empty state
    @pending_enrollments = current_user.teacher_school_enrollments
                                       .where(status: 'pending')
                                       .includes(:school)

    # Initialize empty arrays for sidebar (needed for all views)
    @classes = []
    @classes_awaiting_counts = {}

    # If teacher has pending enrollment and no approved school, show waiting state
    # Check if teacher has any approved enrollment
    has_approved_enrollment = current_user.teacher_school_enrollments.where(status: 'approved').exists?

    if @pending_enrollments.any? && !has_approved_enrollment
      render 'dashboard/pending_school_enrollment'
      return
    end

    # If teacher has no approved enrollment and no pending enrollments, show join form
    if !has_approved_enrollment && @pending_enrollments.empty?
      render 'dashboard/no_school'
      return
    end

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

    # Find subject by slug or UUID
    @subject = Subject.find_by(slug: params[:subject_id]) || Subject.find_by(id: params[:subject_id])
    raise ActiveRecord::RecordNotFound, _('Subject not found') unless @subject

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

    @status_filter = params[:status] || 'unread'

    base_query = Notification.for_school(@school)
                             .for_role('teacher')

    @notifications_list = if @status_filter == 'archived'
                            base_query.read.order(created_at: :desc).limit(50)
                          else
                            base_query.unread.order(created_at: :desc).limit(50)
                          end

    @unread_count = base_query.unread.count
  end

  # POST /dashboard/notifications/mark_as_read
  def mark_notifications_as_read
    notification_ids = params[:notification_ids]

    Notification.where(id: notification_ids).update_all(read_at: Time.current) if notification_ids.present?

    render json: { success: true, marked_count: notification_ids&.count || 0 }
  end

  # GET /dashboard/pupil_videos
  # Moderate student videos
  def pupil_videos
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

    # Get students from current class
    student_ids = @current_class.students.pluck(:id)

    # Filter by status (default: pending for moderation)
    @status_filter = params[:status] || 'pending'

    @videos = StudentVideo.where(user_id: student_ids)
                          .includes(:user, :subject)
                          .order(created_at: :desc)

    @videos = @videos.where(status: @status_filter) if StudentVideo::STATUSES.include?(@status_filter)

    # Count videos by status for tabs
    @videos_pending_count = StudentVideo.where(user_id: student_ids, status: 'pending').count
    @videos_approved_count = StudentVideo.where(user_id: student_ids, status: 'approved').count
    @videos_rejected_count = StudentVideo.where(user_id: student_ids, status: 'rejected').count
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

  # GET /dashboard/class_qr.svg
  def class_qr_svg
    school_class = find_teacher_class(params[:class_id])
    return head :not_found unless school_class

    qr_url = join_class_url(token: school_class.join_token)
    theme = params[:theme] || 'light'

    qr = RQRCode::QRCode.new(qr_url)
    qr_color = theme == 'dark' ? '#ffffff' : '#000000'
    svg = qr.as_svg(
      color: qr_color,
      shape_rendering: 'crispEdges',
      module_size: 6,
      standalone: true,
      use_path: true,
      viewbox: true
    )

    render inline: svg, content_type: 'image/svg+xml'
  end

  # GET /dashboard/class_qr.png
  def class_qr_png
    school_class = find_teacher_class(params[:class_id])
    return head :not_found unless school_class

    qr_url = join_class_url(token: school_class.join_token)
    theme = params[:theme] || 'light'
    is_dark = theme == 'dark'

    qr = RQRCode::QRCode.new(qr_url)
    png = qr.as_png(
      color: is_dark ? 'ffffff' : '000000',
      fill: is_dark ? '000000' : 'ffffff',
      size: 500
    )

    send_data png.to_s, type: 'image/png', disposition: 'attachment',
                        filename: "qr-class-#{school_class.name.parameterize}.png"
  end

  private

  def find_teacher_class(class_id)
    return nil if class_id.blank?

    current_user.assigned_classes.find_by(id: class_id)
  end

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

    # User is logged in but doesn't have teacher role - sign them out and redirect
    sign_out(current_user)

    # Clear any stored return paths to prevent redirect loops
    session.delete(:return_to)
    session.delete(:user_return_to)

    # Redirect to login with teacher role parameter
    # rubocop:disable I18n/GetText/DecorateString
    redirect_to new_user_session_path(role: 'teacher'),
                alert: 'Brak uprawnień nauczyciela. Zaloguj się kontem nauczyciela.'
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
    # Including: student_awaiting_approval, quiz_completed, student_enrollment_request, student_video_pending
    Notification.for_school(school)
                .for_role('teacher')
                .where(notification_type: %w[student_awaiting_approval quiz_completed student_enrollment_request
                                             student_video_pending])
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

    # Videos uploaded by students in this class
    student_ids = @current_class.students.pluck(:id)
    @videos_pending_count = StudentVideo.where(user_id: student_ids, status: 'pending').count

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
