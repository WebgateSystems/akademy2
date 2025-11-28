module Api
  module V1
    class SubjectsController < AuthentificateController
      def index
        result = Api::V1::Subjects::Index.call(params:, current_user:, serializer: SubjectSerializer)
        default_handler(result)
      end
    end
  end
end
