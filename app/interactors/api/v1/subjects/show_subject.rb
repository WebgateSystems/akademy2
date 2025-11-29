# frozen_string_literal: true

module Api
  module V1
    module Subjects
      class ShowSubject < BaseInteractor
        def call
          authorize!
          find_subject
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

        def find_subject
          # Load subject with unit, learning_module and contents
          # Since each subject has one unit, and that unit has one learning_module
          subject = Subject
                    .includes(units: { learning_modules: :contents })
                    .find_by(id: context.params[:id])

          unless subject
            context.message = ['Przedmiot nie został znaleziony']
            context.status = :not_found
            context.fail!
            return
          end

          context.form = subject
          context.status = :ok
          context.serializer = SubjectCompleteSerializer
          # Pass current_user to serializer via params
          context.params = { current_user: current_user }
        end
      end
    end
  end
end
