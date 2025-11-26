# frozen_string_literal: true

module Api
  module V1
    module Headmasters
      class LockHeadmaster < BaseInteractor
        def call
          authorize!
          find_headmaster
          lock_headmaster
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

        def find_headmaster
          context.headmaster = User.joins(:roles).where(id: context.params[:id], roles: { key: 'principal' }).first
          return if context.headmaster

          context.message = ['Dyrektor nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def lock_headmaster
          if context.headmaster.locked_at.present?
            unlock_headmaster
          else
            lock_headmaster_account
          end
          context.status = :ok
        end

        def unlock_headmaster
          context.headmaster.update(
            locked_at: nil,
            failed_attempts: 0,
            unlock_token: nil
          )
          context.form = { message: 'Konto dyrektora zostało odblokowane przez administratora' }
        end

        def lock_headmaster_account
          context.headmaster.update(
            locked_at: Time.current,
            failed_attempts: 0
          )
          context.form = { message: 'Konto dyrektora zostało zablokowane przez administratora' }
        end
      end
    end
  end
end
