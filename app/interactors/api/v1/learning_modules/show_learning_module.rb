# frozen_string_literal: true

module Api
  module V1
    module LearningModules
      class ShowLearningModule < BaseInteractor
        def call
          authorize!
          find_learning_module
        end

        private

        def authorize!
          # Allow access for authenticated users
          return if context.current_user

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def current_user
          context.current_user
        end

        def find_learning_module
          learning_module = LearningModule
                            .includes(unit: :subject, contents: [])
                            .find_by(id: context.params[:id])

          unless learning_module
            context.message = ['Moduł edukacyjny nie został znaleziony']
            context.status = :not_found
            context.fail!
            return
          end

          # Only show published modules (or allow if user has admin access)
          unless learning_module.published? || current_user&.admin?
            context.message = ['Moduł edukacyjny nie jest dostępny']
            context.status = :forbidden
            context.fail!
            return
          end

          context.form = learning_module
          context.status = :ok
          context.serializer = LearningModuleSerializer
        end
      end
    end
  end
end
