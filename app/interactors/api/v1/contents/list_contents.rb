# frozen_string_literal: true

module Api
  module V1
    module Contents
      class ListContents < BaseInteractor
        def call
          authorize!
          load_contents
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

        def load_contents
          # Load contents ordered by learning module > content order
          order_clause = 'subjects.order_index ASC, units.order_index ASC, ' \
                         'learning_modules.order_index ASC, contents.order_index ASC'
          contents = Content
                     .includes(learning_module: { unit: :subject })
                     .order(order_clause)
                     .limit(200)

          # Filter by learning_module_id if provided
          if context.params[:learning_module_id].present?
            contents = contents.where(learning_module_id: context.params[:learning_module_id])
          end

          # Only show contents from published learning modules (unless admin)
          unless current_user&.admin?
            contents = contents.joins(:learning_module).where(learning_modules: { published: true })
          end

          context.form = contents
          context.status = :ok
          context.serializer = ContentSerializer
        end
      end
    end
  end
end
