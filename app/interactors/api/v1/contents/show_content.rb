# frozen_string_literal: true

module Api
  module V1
    module Contents
      class ShowContent < BaseInteractor
        def call
          authorize!
          find_content
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

        def find_content
          content = Content
                    .includes(learning_module: { unit: :subject })
                    .find_by(id: context.params[:id])

          unless content
            context.message = ['Materiał nie został znaleziony']
            context.status = :not_found
            context.fail!
            return
          end

          # Only show contents from published learning modules (unless admin)
          unless content.learning_module.published? || current_user&.admin?
            context.message = ['Materiał nie jest dostępny']
            context.status = :forbidden
            context.fail!
            return
          end

          context.form = content
          context.status = :ok
          context.serializer = ContentSerializer
        end
      end
    end
  end
end
