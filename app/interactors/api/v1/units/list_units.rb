# frozen_string_literal: true

module Api
  module V1
    module Units
      class ListUnits < BaseInteractor
        def call
          authorize!
          load_units
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

        def load_units
          # Load units ordered by subject > unit order
          units = Unit
                  .includes(:subject)
                  .order('subjects.order_index ASC, units.order_index ASC')
                  .limit(200)

          # Filter by subject_id if provided
          units = units.where(subject_id: context.params[:subject_id]) if context.params[:subject_id].present?

          context.form = units
          context.status = :ok
          context.serializer = UnitSerializer
        end
      end
    end
  end
end
