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
          context.school = School.new(school_params)
          context.school.country = 'PL' if context.school.country.blank?
          context.school.slug = context.school.name.parameterize if context.school.slug.blank?
        end

        def school_params
          context.params.require(:school).permit(:name, :slug, :address, :city, :postcode, :country, :phone, :email,
                                                 :homepage, :logo)
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
      end
    end
  end
end
