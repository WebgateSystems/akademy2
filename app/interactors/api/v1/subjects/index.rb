module Api
  module V1
    module Subjects
      class Index < PaginateInteractor
        def call
          # return access_denied unless authorize_project?(:index?)
          return not_found unless school

          context.form = pagination_subjects
          context.pagination = pagination_data
          context.status = :ok
        end

        private

        def pagination_subjects
          begin
            @pagy, @subjects = pagy(objects_scope, page: params[:page])
          rescue Pagy::OverflowError
            no_content
          end

          @subjects
        end

        def school
          current_user.school
        end

        def objects_scope
          school.subjects.order(order_index: :asc)
        end
      end
    end
  end
end
