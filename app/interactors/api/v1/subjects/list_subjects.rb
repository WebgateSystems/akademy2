# frozen_string_literal: true

module Api
  module V1
    module Subjects
      class ListSubjects < BaseInteractor
        def call
          authorize!
          load_subjects
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

        def load_subjects
          # Load global subjects (school_id is nil) ordered by order_index
          # Simple list without full structure
          subjects = Subject
                     .where(school_id: nil)
                     .order(:order_index)
                     .limit(200)

          context.form = subjects
          context.status = :ok
          context.serializer = SubjectSerializer
        end
      end
    end
  end
end
