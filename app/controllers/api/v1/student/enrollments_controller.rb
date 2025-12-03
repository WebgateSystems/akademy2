module Api
  module V1
    module Student
      # This controller uses session-based auth (Devise) instead of JWT
      # because it's called from browser with session cookies
      class EnrollmentsController < ApplicationController
        before_action :authenticate_user!
        before_action :require_student!

        # POST /api/v1/student/enrollments/join
        def join
          return render_error('Token jest wymagany', :unprocessable_entity) if params[:token].blank?

          school_class = SchoolClass.find_by_join_token(params[:token])
          return render_error('Nieprawidłowy token klasy', :not_found) unless school_class
          return render_already_enrolled(school_class) if already_enrolled?(school_class)

          enrollment = create_enrollment(school_class)
          render_enrollment_created(enrollment, school_class)
        end

        # DELETE /api/v1/student/enrollments/:id/cancel
        def cancel
          enrollment = current_user.student_class_enrollments.find_by(id: params[:id])
          return render_error('Nie znaleziono zapisu', :not_found) unless enrollment

          unless enrollment.status == 'pending'
            return render_error('Można anulować tylko oczekujące wnioski',
                                :unprocessable_entity)
          end

          cancel_enrollment(enrollment)
          render json: { success: true, message: 'Wniosek o dołączenie do klasy został anulowany' }, status: :ok
        end

        # GET /api/v1/student/enrollments/pending
        def pending
          enrollments = current_user.student_class_enrollments.where(status: 'pending').includes(school_class: :school)
          render json: { enrollments: serialize_enrollments(enrollments) }, status: :ok
        end

        private

        def require_student!
          return if current_user.student?

          render json: { error: 'Tylko uczniowie mogą korzystać z tej funkcji' }, status: :forbidden
        end

        def render_error(message, status)
          render json: { error: message }, status: status
        end

        def already_enrolled?(school_class)
          StudentClassEnrollment.exists?(student: current_user, school_class: school_class)
        end

        def render_already_enrolled(school_class)
          existing = StudentClassEnrollment.find_by(student: current_user, school_class: school_class)
          render json: {
            error: 'Jesteś już zapisany do tej klasy',
            status: existing.status,
            class_name: school_class.name
          }, status: :unprocessable_entity
        end

        def create_enrollment(school_class)
          enrollment = StudentClassEnrollment.create!(student: current_user, school_class: school_class,
                                                      status: 'pending')
          update_user_school(school_class)
          NotificationService.create_student_enrollment_request(student: current_user, school_class: school_class)
          enrollment
        end

        def update_user_school(school_class)
          current_user.update!(school: school_class.school) if current_user.school.nil?
          student_role = current_user.user_roles.joins(:role).find_by(roles: { key: 'student' })
          student_role&.update!(school: school_class.school) if student_role&.school.nil?
        end

        def render_enrollment_created(enrollment, school_class)
          render json: {
            success: true, message: 'Wniosek o dołączenie do klasy został wysłany',
            enrollment_id: enrollment.id, class_name: school_class.name,
            school_name: school_class.school.name, status: 'pending'
          }, status: :created
        end

        def cancel_enrollment(enrollment)
          school_class = enrollment.school_class
          enrollment.destroy!
          NotificationService.resolve_student_enrollment_request(student: current_user, school_class: school_class)
        end

        def serialize_enrollments(enrollments)
          enrollments.map do |e|
            { id: e.id, class_name: e.school_class.name, school_name: e.school_class.school.name,
              status: e.status, created_at: e.created_at }
          end
        end
      end
    end
  end
end
