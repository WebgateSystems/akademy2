module Api
  module V1
    module Headmasters
      class ListHeadmasters < BaseInteractor
        def call
          authorize!
          load_headmasters
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

        def load_headmasters
          headmasters = User
                        .joins(:roles)
                        .where(roles: { key: 'principal' })
                        .includes(:school)
                        .distinct
                        .order(created_at: :desc)
                        .limit(200)
          context.form = headmasters
          context.status = :ok
          context.serializer = HeadmasterSerializer
        end
      end
    end
  end
end
