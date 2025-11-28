# frozen_string_literal: true

module Api
  module V1
    module Management
      class CreateAcademicYear < BaseInteractor
        def call
          authorize!
          build_academic_year
          save_academic_year
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

        def build_academic_year
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          params_hash = academic_year_params.to_h
          params_hash[:school_id] = school.id

          context.academic_year = AcademicYear.new(params_hash)
        end

        def save_academic_year
          if context.academic_year.save
            context.form = context.academic_year
            context.status = :created
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
      end
    end
  end
end
