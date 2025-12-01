# frozen_string_literal: true

module Api
  module V1
    module Management
      class UpdateAdministration < BaseInteractor
        def call
          authorize!
          find_administration
          prevent_self_role_change
          update_administration
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

        def find_administration
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          # Find user who has at least one administration role (principal or school_manager) for this school
          # They may also have teacher role
          context.administration = User.joins(:user_roles)
                                       .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                                       .where(id: context.params[:id],
                                              user_roles: { school_id: school.id },
                                              roles: { key: %w[principal school_manager teacher] })
                                       .where("EXISTS (SELECT 1 FROM user_roles ur2
                                               INNER JOIN roles r2 ON ur2.role_id = r2.id
                                               WHERE ur2.user_id = users.id
                                               AND ur2.school_id = ?
                                               AND r2.key IN ('principal', 'school_manager'))", school.id)
                                       .distinct
                                       .first

          return if context.administration

          context.message = ['Użytkownik administracji nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def update_administration
          update_params = administration_params.to_h
          merge_metadata(update_params)

          # Ensure school_id cannot be changed
          update_params[:school_id] = school.id

          # Skip Devise confirmation email when updating email (admin action)
          email_changed = update_params[:email].present? && context.administration.email != update_params[:email]
          context.administration.skip_reconfirmation! if email_changed

          if context.administration.update(update_params)
            update_roles
            context.form = context.administration
            context.status = :ok
            context.serializer = AdministrationSerializer
          else
            context.message = context.administration.errors.full_messages
            context.fail!
          end
        end

        def merge_metadata(update_params)
          if update_params[:metadata].present?
            current_metadata = context.administration.metadata || {}
            update_params[:metadata] = current_metadata.deep_merge(update_params[:metadata].symbolize_keys)
          elsif context.params.dig(:administration, :metadata, :phone).present?
            current_metadata = context.administration.metadata || {}
            update_params[:metadata] = current_metadata.merge(
              phone: context.params.dig(:administration, :metadata, :phone)
            )
          end
        end

        def prevent_self_role_change
          return unless context.administration.id == current_user.id

          roles_to_assign = context.params.dig(:administration, :roles)
          return unless roles_to_assign

          # User cannot change their own roles
          context.message = ['Nie możesz zmieniać własnych uprawnień']
          context.status = :forbidden
          context.fail!
        end

        def update_roles
          roles_to_assign = context.params.dig(:administration, :roles)
          return unless roles_to_assign

          # Ensure at least one administration role (principal or school_manager) is assigned
          admin_roles = roles_to_assign.select { |r| %w[principal school_manager].include?(r.to_s) }
          if admin_roles.empty?
            context.message = [
              'Użytkownik musi mieć przynajmniej jedną rolę administracyjną (Principal lub School Manager)'
            ]
            context.fail!
            return
          end

          # Remove existing administration and teacher roles for this school
          context.administration.user_roles
                 .joins(:role)
                 .where(roles: { key: %w[principal school_manager teacher] }, school: school)
                 .destroy_all

          # Assign new roles
          roles_to_assign.each do |role_key|
            next unless %w[principal school_manager teacher].include?(role_key.to_s)

            role = Role.find_by(key: role_key.to_s)
            next unless role

            UserRole.create!(
              user: context.administration,
              role: role,
              school: school
            )
          end
        end

        def administration_params
          # Convert to ActionController::Parameters if it's a hash
          params = if context.params.is_a?(ActionController::Parameters)
                     context.params
                   else
                     ActionController::Parameters.new(context.params)
                   end
          params.require(:administration).permit(:first_name, :last_name, :email, :password,
                                                 :password_confirmation, metadata: {})
        end
      end
    end
  end
end
