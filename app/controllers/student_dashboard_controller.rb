class StudentDashboardController < ApplicationController
  before_action :require_student!
  before_action :load_common_data
  before_action :set_notifications_count
  before_action :set_student_token
  before_action :load_learning_module, only: %i[learning_module quiz submit_quiz result]

  helper_method :can_access_management?

  def index
    # Check if there's a token to auto-fill
    @join_token = params[:token]

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
    # Get all non-quiz contents ordered
    @all_contents = @learning_module.contents.where.not(content_type: 'quiz').order(:order_index)
    @has_quiz = @learning_module.contents.exists?(content_type: 'quiz')

    # Current step (1-based for user-friendliness in URL)
    @current_step = (params[:step].to_i.positive? ? params[:step].to_i : 1)
    @current_step = 1 if @current_step < 1
    @current_step = @all_contents.count if @current_step > @all_contents.count && @all_contents.any?

    # Get current content
    @content = @all_contents.offset(@current_step - 1).first

    # Navigation info
    @total_steps = @all_contents.count
    @is_last_content = @current_step >= @total_steps
    @next_step = @current_step + 1
    @prev_step = @current_step - 1

    # Log content access
    EventLogger.log_content_access(content: @content, user: current_user, action: 'view') if @content

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

    # Create new certificate (has_one)
    ::Api::V1::Certificates::Create.call(params: { quiz_result_id: @quiz_result.id })

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

  # GET /home/videos
  # School videos list with filtering
  def school_videos
    # Find subject by slug or UUID
    @current_subject = find_subject_by_slug_or_id(params[:subject]) if params[:subject].present?

    # Build the query: approved from others OR any status from current user
    if @current_subject.present?
      others_videos = StudentVideo.approved.where.not(user_id: current_user.id).by_subject(@current_subject.id)
      my_videos = StudentVideo.where(user_id: current_user.id).by_subject(@current_subject.id)
    else
      others_videos = StudentVideo.approved.where.not(user_id: current_user.id)
      my_videos = StudentVideo.where(user_id: current_user.id)
    end

    # Search with JOINs to search by author name, school, subject, class
    if params[:q].present?
      query = "%#{params[:q]}%"
      others_videos = apply_video_search(others_videos, query)
      my_videos = apply_video_search(my_videos, query)
    end

    # Add includes for display
    others_videos = others_videos.includes(:subject, :user, :school)
    my_videos = my_videos.includes(:subject, :user, :school)

    # Combine: my videos first, then others, all sorted by newest
    @videos = (my_videos.newest_first.to_a + others_videos.newest_first.to_a)

    @subjects = Subject.where(school_id: [nil, @school&.id]).order(:order_index)
    @my_pending_count = current_user.student_videos.pending.count

    render 'student_dashboard/school_videos'
  end

  # GET /home/videos/new
  # GET /home/videos/new - redirect to videos page (form is now in modal)
  def new_video
    redirect_to student_videos_path
  end

  # POST /home/videos
  # Create new video
  def create_video
    @video = StudentVideo.new(video_params)
    @video.user = current_user
    @video.school = @school
    @video.status = :pending

    # Temporarily disable Searchkick callbacks if index doesn't exist
    begin
      if @video.save
        # Notify teachers about new video
        NotificationService.create_student_video_uploaded(video: @video) if defined?(NotificationService)
        EventLogger.log_student_video_upload(video: @video, user: current_user) if defined?(EventLogger)
        redirect_to student_video_waiting_path
      else
        redirect_to student_videos_path, alert: @video.errors.full_messages.join(', ')
      end
    rescue Searchkick::ImportError => e
      Rails.logger.error "[Searchkick] Import error: #{e.message}"
      # Video was saved but indexing failed - that's OK for now
      redirect_to student_video_waiting_path
    end
  end

  # GET /home/notifications
  # Student notifications page
  def notifications
    @status_filter = params[:status] || 'unread'

    # Build query: notifications for current user OR for student role in same school
    # Use direct SQL to avoid issues with .or() and multiple .where() calls
    base_query = Notification.where(
      '(user_id = :uid) OR (user_id IS NULL AND target_role = :role AND school_id = :sid)',
      uid: current_user.id,
      role: 'student',
      sid: @school.id
    ).where(notification_type: %w[student_video_approved student_video_rejected quiz_completed])

    @notifications_list = if @status_filter == 'archived'
                            base_query.read.order(created_at: :desc).limit(50)
                          else
                            base_query.unread.order(created_at: :desc).limit(50)
                          end

    @unread_count = base_query.unread.count
  end

  # POST /home/notifications/mark_as_read
  def mark_notifications_as_read
    # Rails automatically parses JSON body to params when Content-Type is application/json
    notification_ids = params[:notification_ids]
    notification_ids = JSON.parse(notification_ids) if notification_ids.is_a?(String)

    marked_count = 0
    if notification_ids.present?
      # Ensure it's an array
      notification_ids = Array(notification_ids) unless notification_ids.is_a?(Array)

      # Use the same query logic as in notifications action
      base_query = Notification.where(
        '(user_id = :uid) OR (user_id IS NULL AND target_role = :role AND school_id = :sid)',
        uid: current_user.id,
        role: 'student',
        sid: @school.id
      ).where(notification_type: %w[student_video_approved student_video_rejected quiz_completed])

      # Only update notifications that match the query AND are in the provided IDs
      marked_count = base_query.where(id: notification_ids).update_all(read_at: Time.current)
    end

    render json: { success: true, marked_count: marked_count }
  end

  # GET /home/videos/waiting
  # Waiting for approval page
  def video_waiting
    render 'student_dashboard/video_waiting'
  end

  # DELETE /home/videos/:id
  # Delete own video (only pending or rejected)
  def destroy_video
    @video = StudentVideo.find_by(id: params[:id])

    unless @video
      return respond_to do |format|
        format.html { redirect_to student_videos_path, alert: t('student_dashboard.videos.not_found') }
        format.json { render json: { success: false, error: 'Video not found' }, status: :not_found }
      end
    end

    unless @video.user_id == current_user.id
      return respond_to do |format|
        format.html { redirect_to student_videos_path, alert: t('student_dashboard.videos.not_authorized') }
        format.json { render json: { success: false, error: 'Not authorized' }, status: :forbidden }
      end
    end

    unless @video.pending? || @video.rejected?
      return respond_to do |format|
        format.html { redirect_to student_videos_path, alert: t('student_dashboard.videos.cannot_delete') }
        format.json do
          render json: { success: false, error: 'Can only delete pending or rejected videos' },
                 status: :unprocessable_entity
        end
      end
    end

    @video.destroy
    EventLogger.log_student_video_delete(video: @video, user: current_user) if defined?(EventLogger)

    respond_to do |format|
      format.html { redirect_to student_videos_path, notice: t('student_dashboard.videos.deleted') }
      format.json { render json: { success: true } }
    end
  end

  # POST /home/contents/:id/like
  def toggle_content_like
    @content = Content.find_by(id: params[:id])

    return render json: { success: false, error: 'Content not found' }, status: :not_found unless @content

    unless @content.likeable?
      return render json: { success: false, error: 'This content cannot be liked' }, status: :unprocessable_entity
    end

    liked = @content.toggle_like!(current_user)
    render json: {
      success: true,
      liked: liked,
      likes_count: @content.likes_count
    }
  end

  # GET /home/account
  def account
    @user = current_user
    render 'student_dashboard/account'
  end

  # PATCH /home/account
  # Students can only update email (if unverified) and phone (if unverified)
  def update_account
    @user = current_user
    has_changes = false

    # Email can only be changed if NOT verified
    if params[:user][:email].present? && params[:user][:email] != @user.email && @user.confirmed_at.blank?
      @user.skip_reconfirmation!
      @user.email = params[:user][:email]
      has_changes = true
    end

    # Phone can only be changed if NOT verified
    phone_verified = @user.metadata&.dig('phone_verified') == true
    if params[:user][:phone].present? && params[:user][:phone] != @user.phone && !phone_verified
      @user.phone = params[:user][:phone]
      has_changes = true
    end

    if !has_changes
      redirect_to student_account_path, notice: t('student_dashboard.account.no_changes')
    elsif @user.save
      redirect_to student_account_path, notice: t('student_dashboard.account.updated')
    else
      render 'student_dashboard/account', status: :unprocessable_entity
    end
  end

  # GET /home/account/settings
  def settings
    @user = current_user
    render 'student_dashboard/settings'
  end

  # PATCH /home/account/settings
  def update_settings
    @user = current_user

    # Handle PIN change with confirmation
    # For students, PIN is stored as their password (4-digit numeric)
    new_pin = params[:user][:new_pin]
    pin_confirmation = params[:user][:pin_confirmation]

    if new_pin.present?
      if new_pin.length != 4
        @user.errors.add(:base, t('student_dashboard.settings.pin_length_error'))
        return render 'student_dashboard/settings', status: :unprocessable_entity
      end

      unless new_pin.match?(/^\d{4}$/)
        @user.errors.add(:base, t('student_dashboard.settings.pin_digits_only'))
        return render 'student_dashboard/settings', status: :unprocessable_entity
      end

      if new_pin != pin_confirmation
        @user.errors.add(:base, t('student_dashboard.settings.pin_mismatch'))
        return render 'student_dashboard/settings', status: :unprocessable_entity
      end

      # PIN is stored as password for students
      @user.password = new_pin
      @user.password_confirmation = pin_confirmation
    end

    @user.locale = settings_params[:locale] if settings_params[:locale].present?

    if @user.save
      # Re-sign in the user after password change to maintain session
      bypass_sign_in(@user) if new_pin.present?
      redirect_to student_account_path, notice: t('student_dashboard.settings.updated')
    else
      render 'student_dashboard/settings', status: :unprocessable_entity
    end
  end

  # DELETE /home/account
  # POST /home/account/request-deletion
  # Instead of deleting directly, sends a request to school administration
  def request_account_deletion
    @user = current_user

    # Use NotificationService to create notification for all school managers
    NotificationService.create_account_deletion_request(student: @user, school: @user.school)

    redirect_to student_account_path, notice: t('student_dashboard.account.deletion_requested')
  end

  private

  def set_student_token
    return unless current_user

    @student_token = Jwt::TokenService.encode({ user_id: current_user.id })
  end

  def set_notifications_count
    return unless current_user

    # Count unread notifications for student
    # Use the same query logic as in notifications action
    base_query = Notification.where(
      '(user_id = ? OR (user_id IS NULL AND target_role = ? AND school_id = ?)) AND notification_type IN (?)',
      current_user.id,
      'student',
      @school&.id,
      %w[student_video_approved student_video_rejected quiz_completed]
    )

    @notifications_count = base_query.unread.count
  end

  def video_params
    params.permit(:title, :description, :subject_id, :file)
  end

  def account_params
    # Students cannot change name/birthdate - only email and phone if unverified
    params.require(:user).permit(:email, :phone)
  end

  def settings_params
    params.require(:user).permit(:locale, :theme, :new_pin, :pin_confirmation)
  end

  def searchkick_available?
    return false if Rails.env.test? && ENV['ELASTICSEARCH_TEST'] != 'true'

    StudentVideo.searchkick_index.exists?
  rescue StandardError
    false
  end

  def require_student!
    return if user_signed_in? && current_user.student?

    # If user is logged in but not a student, sign them out first
    if user_signed_in?
      sign_out(current_user)
      session.delete(:return_to)
      session.delete(:user_return_to)
    else
      # Save return path for after login
      session[:user_return_to] = request.fullpath
    end

    # Redirect to login with student role (consistent with other dashboards)
    # rubocop:disable I18n/GetText/DecorateString
    redirect_to student_login_path,
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

    # Get best quiz results for each module
    quiz_results = QuizResult.where(user_id: current_user.id, learning_module_id: module_ids)
    best_score = quiz_results.maximum(:score) || 0

    # Get pass threshold from quiz content (default 80 if not set)
    quiz_content = Content.joins(learning_module: { unit: :subject })
                          .where(content_type: 'quiz', learning_modules: { id: module_ids })
                          .first
    pass_threshold = quiz_content&.payload&.dig('pass_threshold') || 80

    {
      best_score: best_score,
      pass_threshold: pass_threshold,
      passed: best_score >= pass_threshold,
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
    @current_class = @classes.first
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

  def find_subject_by_slug_or_id(slug_or_id)
    return nil if slug_or_id.blank?

    Subject.find_by(slug: slug_or_id) || Subject.find_by(id: slug_or_id)
  end

  # Apply search across multiple fields with JOINs
  def apply_video_search(scope, query)
    scope
      .joins(:user)
      .joins('LEFT JOIN schools ON schools.id = student_videos.school_id')
      .joins('LEFT JOIN subjects ON subjects.id = student_videos.subject_id')
      .joins('LEFT JOIN student_class_enrollments ON student_class_enrollments.student_id = users.id')
      .joins('LEFT JOIN school_classes ON school_classes.id = student_class_enrollments.school_class_id')
      .where(
        'student_videos.title ILIKE :q OR ' \
        'student_videos.description ILIKE :q OR ' \
        'users.first_name ILIKE :q OR ' \
        'users.last_name ILIKE :q OR ' \
        "CONCAT(users.first_name, ' ', users.last_name) ILIKE :q OR " \
        'schools.name ILIKE :q OR ' \
        'subjects.title ILIKE :q OR ' \
        'school_classes.name ILIKE :q',
        q: query
      )
      .distinct
  end
end
