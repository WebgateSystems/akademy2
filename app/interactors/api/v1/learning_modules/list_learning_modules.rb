# frozen_string_literal: true

module Api
  module V1
    module LearningModules
      class ListLearningModules < BaseInteractor
        def call
          authorize!
          load_learning_modules
        end

        private

        def authorize!
          # Allow access for authenticated users (students, teachers, etc.)
          return if context.current_user

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def current_user
          context.current_user
        end

        def load_learning_modules
          # Load only published learning modules, ordered by subject > unit > module order
          learning_modules = LearningModule
                             .includes(unit: :subject)
                             .published
                             .order('subjects.order_index ASC, units.order_index ASC, learning_modules.order_index ASC')
                             .limit(200)

          context.form = learning_modules
          context.status = :ok
          context.serializer = LearningModuleSerializer
        end
      end
    end
  end
end
