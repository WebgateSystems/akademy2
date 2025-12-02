class QuizResult < ApplicationRecord
  belongs_to :user
  belongs_to :learning_module

  after_create :log_quiz_completion
  after_create :notify_teachers_on_success

  private

  def log_quiz_completion
    EventLogger.log_quiz_complete(quiz_result: self, user: user)
  end

  def notify_teachers_on_success
    return unless score && score >= 80

    NotificationService.create_quiz_success_notification(
      student: user,
      quiz_result: self
    )
  end
end
