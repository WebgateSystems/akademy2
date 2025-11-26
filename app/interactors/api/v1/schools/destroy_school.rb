module Api
  module V1
    module Schools
      class DestroySchool < BaseInteractor
        def call
          authorize!
          find_school
          destroy_school
        end

        private

        def authorize!
          policy = AdminPolicy.new(current_user, :admin)
          return if policy.access?

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def current_user
          context.current_user
        end

        def find_school
          context.school = School.find_by(id: context.params[:id])
          return if context.school

          context.message = ['Szkoła nie została znaleziona']
          context.status = :not_found
          context.fail!
        end

        def destroy_school
          if context.school.destroy
            context.status = :no_content
          else
            context.message = context.school.errors.full_messages
            context.fail!
          end
        end
      end
    end
  end
end
