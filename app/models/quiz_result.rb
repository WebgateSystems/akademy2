class QuizResult < ApplicationRecord
  belongs_to :user
  belongs_to :learning_module
end
