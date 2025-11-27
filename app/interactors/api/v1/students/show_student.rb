# frozen_string_literal: true

module Api
  module V1
    module Students
      class ShowStudent < BaseInteractor
        def call
          authorize!
          find_student
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

        def find_student
          student = User.joins(:roles).where(id: context.params[:id], roles: { key: 'student' }).first
          unless student
            context.message = ['Uczeń nie został znaleziony']
            context.status = :not_found
            context.fail!
            return
          end
          context.form = student
          context.status = :ok
          context.serializer = StudentSerializer
        end
      end
    end
  end
end
