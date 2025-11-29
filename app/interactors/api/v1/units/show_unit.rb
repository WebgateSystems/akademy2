# frozen_string_literal: true

module Api
  module V1
    module Units
      class ShowUnit < BaseInteractor
        def call
          authorize!
          find_unit
        end

        private

        def authorize!
          # Allow access for authenticated users
          return if context.current_user

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def current_user
          context.current_user
        end

        def find_unit
          unit = Unit.includes(:subject).find_by(id: context.params[:id])

          unless unit
            context.message = ['Jednostka nie została znaleziona']
            context.status = :not_found
            context.fail!
            return
          end

          context.form = unit
          context.status = :ok
          context.serializer = UnitSerializer
        end
      end
    end
  end
end
