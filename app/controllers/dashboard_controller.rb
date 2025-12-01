class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher!

  helper_method :can_access_management?

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

  private

  def require_teacher!
    return if current_user.teacher?

    redirect_to root_path, alert: 'Dostęp tylko dla nauczycieli'
  end

  def can_access_management?
    return false unless current_user

    user_roles = current_user.roles.pluck(:key)
    user_roles.include?('principal') || user_roles.include?('school_manager')
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
          if student_answer
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
