module Api
  module V1
    module Certificates
      class Create < BaseInteractor
        def call
          return not_found unless quiz_result

          find_or_prepare_certificate

          build_certificate_record
          generate_pdf
          upload_pdf
          finalize_certificate

          context.form = @certificate
        end

        private

        def quiz_result
          @quiz_result ||= ::QuizResult.find_by(id: context.params[:quiz_result_id])
        end

        def find_or_prepare_certificate
          @certificate = quiz_result.certificate
          @certificate&.issued_at = Time.current
        end

        def build_certificate_record
          @certificate ||= Certificate.new(
            id: SecureRandom.uuid,
            quiz_result: quiz_result,
            certificate_number: SecureRandom.uuid
          )

          @certificate.issued_at = Time.current
        end

        def generate_pdf
          @pdf_binary = CertificatePdf.build(
            module_name: quiz_result.learning_module.unit.title,
            student_name: "#{quiz_result.user.first_name} #{quiz_result.user.last_name}",
            result: quiz_result.score,
            teacher_name: "#{teacher.first_name} #{teacher.last_name}"
          )
        end

        def teacher
          student = quiz_result.user
          student.school_classes.find_by(year: student.school.current_academic_year_value).main_teacher ||
            student.school_classes.find_by(year: student.school.current_academic_year_value).teachers.first ||
            Struct.new(:first_name, :last_name).new('Jonh', 'Doe')
        end

        def upload_pdf
          tmp = Tempfile.new(['cert', '.pdf'])
          tmp.binmode
          tmp.write(@pdf_binary)
          tmp.rewind

          @certificate.pdf = tmp
        ensure
          tmp.close
        end

        def finalize_certificate
          @certificate.save!
        end
      end
    end
  end
end
