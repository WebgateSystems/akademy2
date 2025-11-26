module Api
  module V1
    module Register
      module Flows
        class Create < BaseInteractor
          def call
            context.form = RegistrationFlow.create!
            context.status = :created
          end
        end
      end
    end
  end
end
