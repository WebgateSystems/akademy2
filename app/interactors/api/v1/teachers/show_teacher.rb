# frozen_string_literal: true

module Api
  module V1
    module Teachers
      class ShowTeacher < BaseInteractor
        def call
          authorize!
          find_teacher
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

        def find_teacher
          teacher = User.joins(:roles).where(id: context.params[:id], roles: { key: 'teacher' }).first
          unless teacher
            context.message = ['Nauczyciel nie został znaleziony']
            context.status = :not_found
            context.fail!
            return
          end
          context.form = teacher
          context.status = :ok
          context.serializer = TeacherSerializer
        end
      end
    end
  end
end
