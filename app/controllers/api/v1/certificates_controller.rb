module Api
  module V1
    class CertificatesController < ApplicationApiController
      def show
        result = Api::V1::Certificates::Show.call(params:, serializer: CertificateSerializer)
        default_handler(result)
      end

      def download
        result = Api::V1::Certificates::Download.call(params:)

        return render(json: { errors: result.message }, status: result.status) unless result.success?

        send_file result.file_path,
                  filename: result.filename,
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end
end
