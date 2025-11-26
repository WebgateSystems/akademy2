module Api
  module V1
    module Schools
      class ShowSchool < BaseInteractor
        def call
          authorize!
          find_school
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
          unless context.school
            context.message = ['Szkoła nie została znaleziona']
            context.status = :not_found
            context.fail!
            return
          end
          context.form = context.school
          context.status = :ok
          context.serializer = SchoolSerializer
        end
      end
    end
  end
end
