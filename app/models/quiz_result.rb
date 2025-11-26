class QuizResult < ApplicationRecord
  belongs_to :user
  belongs_to :learning_module

  after_create :log_quiz_completion

  private

  def log_quiz_completion
    EventLogger.log_quiz_complete(quiz_result: self, user: user)
  end
end
