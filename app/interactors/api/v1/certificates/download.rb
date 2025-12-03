module Api
  module V1
    module Certificates
      class Download < BaseInteractor
        def call
          return not_found unless certificate

          context.file_path = certificate.pdf.path
          context.filename  = "certificate-#{certificate.id}.pdf"

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
