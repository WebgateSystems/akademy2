# frozen_string_literal: true

module DashboardHelper
  def result_badge_class(score)
    case score
    when 0...50
      'quiz-result-badge--bad'
    when 50...75
      'quiz-result-badge--average'
    else
      'quiz-result-badge--good'
    end
  end

  def result_badge_text(score)
    case score
    when 0...50
      'Bad'
    when 50...75
      'Average'
    else
      'Good'
    end
  end

  # Get student's answer for a specific question
  # Returns hash with :status (is-good, is-bad, is-empty), :question_text, :answer
  def get_student_answer(student_id, question_num)
    # Check if we have quiz answers data for this student
    answers = @student_answers&.dig(student_id) || {}
    answer = answers[question_num]
    question = @questions&.dig(question_num)

    if answer.nil?
      # No answer yet - show question text and correct answer for reference
      {
        status: 'is-empty',
        question_text: question&.dig(:text),
        answer: question ? "Poprawna: #{question[:correct_answer]}" : nil
      }
    elsif answer[:correct]
      { status: 'is-good', question_text: answer[:question_text], answer: answer[:answer] }
    else
      { status: 'is-bad', question_text: answer[:question_text], answer: answer[:answer] }
    end
  end

  # Calculate total score for a student (10 points per correct answer)
  def calculate_student_score(student_id)
    answers = @student_answers&.dig(student_id) || {}
    correct_count = answers.values.compact.count { |a| a[:correct] }
    correct_count * 10
  end
end

