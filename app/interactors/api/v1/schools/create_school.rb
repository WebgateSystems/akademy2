# frozen_string_literal: true

module Api
  module V1
    module Schools
      class CreateSchool < BaseInteractor
        def call
          authorize!
          build_school
          save_school
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

        def build_school
          params_hash = school_params.to_h
          context.school = School.new(params_hash)
        end

        def save_school
          if context.school.save
            context.form = context.school
            context.status = :created
            context.serializer = SchoolSerializer
          else
            context.message = context.school.errors.full_messages
            context.fail!
          end
        end

        def school_params
          permitted = context.params.require(:school).permit(:name, :slug, :address, :city, :postcode, :country,
                                                             :phone, :email, :homepage, :logo)
          # Generate slug if blank and name present
          permitted[:slug] = permitted[:name].parameterize if permitted[:slug].blank? && permitted[:name].present?
          permitted
        end
      end
    end
  end
end
