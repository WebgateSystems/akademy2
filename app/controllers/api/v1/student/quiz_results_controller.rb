# frozen_string_literal: true

module Api
  module V1
    module Student
      class QuizResultsController < ApplicationApiController
        before_action :authorize_access_request!
        before_action :require_student!

        # POST /api/v1/student/quiz_results
        # Submit completed quiz result
        def create
          learning_module = LearningModule.find(params[:learning_module_id])

          # Verify student has access to this module
          subject = learning_module.unit.subject
          unless subject.school_id.nil? || subject.school_id == current_user.school_id
            return render json: { success: false, error: 'Access denied' }, status: :forbidden
          end

          score = params[:score].to_i
          passed = score >= 80

          # Create or update quiz result
          quiz_result = QuizResult.find_or_initialize_by(
            user_id: current_user.id,
            learning_module_id: learning_module.id
          )

          # Only update if new score is better or it's first attempt
          if quiz_result.new_record? || score > (quiz_result.score || 0)
            quiz_result.assign_attributes(
              score: score,
              passed: passed,
              details: params[:details] || {},
              completed_at: Time.current
            )
            quiz_result.save!
            ::Api::V1::Certificates::Create(params: { quiz_result_id: quiz_result.id })
          end

          # Log the quiz completion event
          EventLogger.log_quiz_complete(quiz_result: quiz_result, user: current_user)

          render json: {
            success: true,
            data: {
              id: quiz_result.id,
              score: quiz_result.score,
              passed: quiz_result.passed,
              completed_at: quiz_result.completed_at,
              message: passed ? 'Congratulations! You passed the quiz.' : 'Keep practicing! You need 80% to pass.'
            }
          }, status: quiz_result.previously_new_record? ? :created : :ok
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: 'Learning module not found' }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        end

        # GET /api/v1/student/quiz_results
        # Get all quiz results for current student
        def index
          results = QuizResult.where(user_id: current_user.id)
                              .includes(learning_module: { unit: :subject })
                              .order(completed_at: :desc)

          render json: {
            success: true,
            data: results.map do |result|
              {
                id: result.id,
                score: result.score,
                passed: result.passed,
                completed_at: result.completed_at,
                learning_module: {
                  id: result.learning_module.id,
                  title: result.learning_module.title
                },
                subject: {
                  id: result.learning_module.unit.subject.id,
                  title: result.learning_module.unit.subject.title
                }
              }
            end
          }
        end

        private

        def require_student!
          return if current_user.student?

          render json: { success: false, error: 'Student access required' }, status: :forbidden
        end
      end
    end
  end
end
