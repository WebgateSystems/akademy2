module Api
  module V1
    module Certificates
      class Show < BaseInteractor
        def call
          return not_found unless certificate

          context.form = certificate
          context.status = :ok
        end

        private

        def certificate
          ::Certificate.find_by(id: context.params[:id])
        end
      end
    end
  end
end
