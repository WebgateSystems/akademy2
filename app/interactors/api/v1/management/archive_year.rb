# frozen_string_literal: true

module Api
  module V1
    module Management
      class ArchiveYear < BaseInteractor
        def call
          authorize!
          archive_year
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

        # rubocop:disable Metrics/MethodLength
        def archive_year
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          year = get_param_value(:year) || '2025/2026'
          classes = SchoolClass.where(school: school, year: year)

          if classes.any?
            # Archive year by updating metadata or creating archive record
            # For now, we'll just mark it as archived in metadata
            classes.find_each do |school_class|
              metadata = school_class.metadata || {}
              metadata['archived'] = true
              metadata['archived_at'] = Time.current.iso8601
              school_class.update(metadata: metadata)
            end

            context.form = { message: "Academic year #{year} has been archived" }
            context.status = :ok
          else
            context.message = ['Brak klas do zarchiwizowania']
            context.fail!
          end
        end
        # rubocop:enable Metrics/MethodLength

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
