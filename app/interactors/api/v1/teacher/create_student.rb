# frozen_string_literal: true

module Api
  module V1
    module Teacher
      class CreateStudent < BaseInteractor
        def call
          authorize!
          validate_class_access
          build_student
          save_student
        end

        private

        def authorize!
          context.fail!(message: ['Brak uprawnień']) unless current_user && teacher_role?
        end

        def teacher_role? = current_user.user_roles.joins(:role).exists?(roles: { key: 'teacher' })
        def current_user = context.current_user

        def school
          @school ||= current_user.school || current_user.user_roles.joins(:role)
                                                         .where(roles: { key: 'teacher' }).first&.school
        end

        def school_class = @school_class ||= SchoolClass.find_by(id: context.params.dig(:student, :school_class_id))

        def validate_class_access
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school
          return context.fail!(message: ['Nie podano klasy']) unless school_class

          context.fail!(message: ['Brak dostępu do tej klasy']) unless teacher_has_class_access?
        end

        def teacher_has_class_access? = TeacherClassAssignment.exists?(teacher: current_user,
                                                                       school_class: school_class)

        def build_student
          params_hash = student_params.to_h
          handle_metadata(params_hash)
          generate_credentials(params_hash)
          params_hash[:school_id] = school.id
          params_hash.delete(:school_class_id)
          context.student = User.new(params_hash)
        end

        def handle_metadata(params_hash)
          return if params_hash[:metadata].blank?

          params_hash[:metadata] = params_hash[:metadata].symbolize_keys
          return unless params_hash[:metadata][:birth_date].present? && params_hash[:birthdate].blank?

          params_hash[:birthdate] =
            params_hash[:metadata][:birth_date]
        end

        def generate_credentials(params_hash)
          generate_email(params_hash) if params_hash[:email].blank?
          generate_phone(params_hash) if params_hash.dig(:metadata, :phone).blank? && params_hash[:phone].blank?
          context.fail!(message: ['PIN jest wymagany']) if params_hash[:password].blank?
        end

        def generate_email(params_hash)
          first = normalize_name(params_hash[:first_name])
          last = normalize_name(params_hash[:last_name])
          params_hash[:email] = find_unique_email(first, last)
        end

        def normalize_name(name) = if name.blank?
                                     'user'
                                   else
                                     I18n.transliterate(name.to_s.downcase.strip).gsub(
                                       /[^a-z0-9]/, ''
                                     )
                                   end

        def find_unique_email(first, last)
          base = "#{first}.#{last}@#{school.slug}.akademy.pl"
          return base unless User.exists?(email: base)

          (1..1000).each do |i|
            candidate = "#{first}.#{last}#{i}@#{school.slug}.akademy.pl"
            return candidate unless User.exists?(email: candidate)
          end
          "#{first}.#{last}.#{SecureRandom.hex(4)}@#{school.slug}.akademy.pl"
        end

        def generate_phone(params_hash)
          params_hash[:metadata] ||= {}
          params_hash[:metadata][:phone] = find_unique_phone
        end

        def find_unique_phone
          100.times do
            phone = "+48#{rand(100_000_000..999_999_999)}"
            return phone unless User.where("metadata->>'phone' = ?", phone).exists?
          end
          "+48#{SecureRandom.random_number(10**9).to_s.rjust(9, '0')}"
        end

        def student_params
          p = context.params.is_a?(ActionController::Parameters) ? context.params : ActionController::Parameters.new(context.params)
          p.require(:student).permit(:first_name, :last_name, :email, :password, :password_confirmation,
                                     :school_class_id, :birthdate, metadata: {})
        end

        def save_student
          context.student.skip_confirmation!
          return context.fail!(message: context.student.errors.full_messages) unless context.student.save

          finalize_enrollment
        end

        def finalize_enrollment
          Role.find_by(key: 'student')&.then do |r|
            UserRole.find_or_create_by!(user: context.student, role: r, school: school)
          end
          StudentClassEnrollment.find_or_create_by!(student: context.student, school_class: school_class) do |e|
            e.status = 'approved'
            e.joined_at = Time.current
          end
          context.form = context.student
          context.status = :created
          context.serializer = StudentSerializer
        end
      end
    end
  end
end
