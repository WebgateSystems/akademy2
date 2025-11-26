module Api
  module V1
    module Headmasters
      class ShowHeadmaster < BaseInteractor
        def call
          authorize!
          find_headmaster
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

        def find_headmaster
          headmaster = User.joins(:roles).where(id: context.params[:id], roles: { key: 'principal' }).first
          unless headmaster
            context.message = ['Dyrektor nie został znaleziony']
            context.status = :not_found
            context.fail!
            return
          end
          context.form = headmaster
          context.status = :ok
          context.serializer = HeadmasterSerializer
        end
      end
    end
  end
end
