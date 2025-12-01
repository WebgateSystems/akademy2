# frozen_string_literal: true

module Api
  module V1
    module Management
      class ParentsController < Api::V1::Management::BaseController
        include HandleStatusCode

        def index
          result = ListParents.call(current_user: current_user,
                                    params: params.permit(:page, :per_page,
                                                          :search, :q, parent: {}))
          default_handler(result)
        end

        def show
          result = ShowParent.call(current_user: current_user, params: params.permit(:id, parent: {}))
          default_handler(result)
        end

        def create
          result = CreateParent.call(current_user: current_user, params: parent_params)
          default_handler(result)
        end

        def update
          result = UpdateParent.call(current_user: current_user, params: parent_params.merge(id: params[:id]))
          default_handler(result)
        end

        def destroy
          result = DestroyParent.call(current_user: current_user, params: params.permit(:id, parent: {}))
          default_handler(result)
        end

        def resend_invite
          result = ResendInviteParent.call(current_user: current_user, params: params.permit(:id, parent: {}))
          default_handler(result)
        end

        def lock
          result = LockParent.call(current_user: current_user, params: params.permit(:id, parent: {}))
          default_handler(result)
        end

        def search_students
          result = SearchStudentsForParent.call(current_user: current_user,
                                                params: params.permit(
                                                  :q, :search, parent: {}
                                                ))
          default_handler(result)
        end

        private

        def parent_params
          params.require(:parent).permit(
            :first_name, :last_name, :email, :phone, :relation,
            metadata: {},
            student_ids: []
          ).tap do |permitted|
            # Convert student_ids array to proper format
            if params[:parent][:student_ids].is_a?(Array)
              permitted[:student_ids] = params[:parent][:student_ids].reject(&:blank?)
            end
          end
        end
      end
    end
  end
end
