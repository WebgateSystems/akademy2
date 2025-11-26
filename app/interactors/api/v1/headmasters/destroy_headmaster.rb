module Api
  module V1
    module Headmasters
      class DestroyHeadmaster < BaseInteractor
        def call
          authorize!
          find_headmaster
          destroy_headmaster
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
          context.headmaster = User.joins(:roles).where(id: context.params[:id], roles: { key: 'principal' }).first
          return if context.headmaster

          context.message = ['Dyrektor nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def destroy_headmaster
          if context.headmaster.destroy
            context.status = :no_content
          else
            context.message = context.headmaster.errors.full_messages
            context.fail!
          end
        end
      end
    end
  end
end

