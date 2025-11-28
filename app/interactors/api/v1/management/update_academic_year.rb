# frozen_string_literal: true

module Api
  module V1
    module Management
      class UpdateAcademicYear < BaseInteractor
        def call
          authorize!
          find_academic_year
          update_academic_year
        end

        private

        def authorize!
          policy = SchoolManagementPolicy.new(current_user, :school_management)
          return if policy.access?

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def current_user
          context.current_user
        end

        def school
          @school ||= begin
            user_school = current_user.school
            return user_school if user_school

            user_role = current_user.user_roles
                                    .joins(:role)
                                    .where(roles: { key: %w[principal school_manager] })
                                    .first
            user_role&.school
          end
        end

        def find_academic_year
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          year_id = get_param_value(:id)
          context.academic_year = AcademicYear.find_by(id: year_id, school: school)

          return if context.academic_year

          context.message = ['Rok akademicki nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def update_academic_year
          if context.academic_year.update(academic_year_params)
            context.form = context.academic_year
            context.status = :ok
            context.serializer = AcademicYearSerializer
          else
            # Format errors for better display
            error_messages = context.academic_year.errors.full_messages.map do |msg|
              # Translate common ActiveRecord errors
              msg.gsub(/Year\s+/, 'Rok ').gsub(/School\s+/, 'Szkoła ')
            end
            context.message = error_messages
            context.fail!
          end
        end

        def academic_year_params
          # Convert to ActionController::Parameters if it's a hash
          params = if context.params.is_a?(ActionController::Parameters)
                     context.params
                   else
                     ActionController::Parameters.new(context.params)
                   end
          params = params.require(:academic_year).permit(:year, :started_at, :is_current)
          # Auto-calculate started_at from year if not provided
          if params[:started_at].blank? && params[:year].present?
            year_parts = params[:year].split('/')
            start_year = year_parts[0].to_i
            params[:started_at] = Date.new(start_year, 9, 1) if start_year.positive?
          end
          params
        end

        def get_param_value(*keys)
          current_params = context.params
          keys.each do |key|
            current_params = if current_params.is_a?(ActionController::Parameters)
                               current_params[key]
                             elsif current_params.is_a?(Hash)
                               current_params[key.to_s] || current_params[key.to_sym]
                             end
            return nil if current_params.nil?
          end
          current_params
        end
      end
    end
  end
end
