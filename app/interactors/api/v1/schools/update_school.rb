module Api
  module V1
    module Schools
      class UpdateSchool < BaseInteractor
        def call
          authorize!
          find_school
          update_school
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

        def find_school
          context.school = School.find_by(id: context.params[:id])
          return if context.school

          context.message = ['Szkoła nie została znaleziona']
          context.status = :not_found
          context.fail!
        end

        def update_school
          if context.school.update(school_params)
            context.form = context.school
            context.status = :ok
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
