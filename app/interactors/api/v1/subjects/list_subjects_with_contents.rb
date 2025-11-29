# frozen_string_literal: true

module Api
  module V1
    module Subjects
      class ListSubjectsWithContents < BaseInteractor
        def call
          authorize!
          load_subjects_with_contents
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

        def load_subjects_with_contents
          # Load all global subjects with full structure (unit → learning_module → contents)
          # Since each subject has one unit, and that unit has one learning_module
          subjects = Subject
                     .includes(units: { learning_modules: :contents })
                     .where(school_id: nil)
                     .order(:order_index)
                     .limit(200)

          context.form = subjects
          context.status = :ok
          context.serializer = SubjectCompleteSerializer
          # Pass current_user to serializer via params
          context.params = { current_user: current_user }
        end
      end
    end
  end
end
