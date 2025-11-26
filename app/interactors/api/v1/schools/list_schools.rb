module Api
  module V1
    module Schools
      class ListSchools < BaseInteractor
        def call
          authorize!
          load_schools
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

        def load_schools
          schools = School.order(created_at: :desc).limit(200)
          context.form = schools
          context.status = :ok
          context.serializer = SchoolSerializer
        end
      end
    end
  end
end
