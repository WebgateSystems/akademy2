module Api
  module V1
    module Teacher
      # This controller uses session-based auth (Devise) instead of JWT
      # because it's called from browser with session cookies
      class SchoolEnrollmentsController < ApplicationController
        before_action :authenticate_user!
        before_action :require_teacher!

        # POST /api/v1/teacher/school_enrollments/join
        def join
          return render_error('Token jest wymagany', :unprocessable_entity) if params[:token].blank?

          school = School.find_by(join_token: params[:token])
          return render_error('Nieprawidłowy token szkoły', :not_found) unless school
          return render_already_enrolled(school) if already_enrolled?(school)

          enrollment = create_enrollment(school)
          render_enrollment_created(enrollment, school)
        end

        # DELETE /api/v1/teacher/school_enrollments/:id/cancel
        def cancel
          enrollment = current_user.teacher_school_enrollments.find_by(id: params[:id])
          return render_error('Nie znaleziono zapisu', :not_found) unless enrollment

          unless enrollment.status == 'pending'
            return render_error('Można anulować tylko oczekujące wnioski',
                                :unprocessable_entity)
          end

          cancel_enrollment(enrollment)
          render json: { success: true, message: 'Wniosek o dołączenie do szkoły został anulowany' }, status: :ok
        end

        # GET /api/v1/teacher/school_enrollments/pending
        def pending
          enrollments = current_user.teacher_school_enrollments.where(status: 'pending').includes(:school)
          render json: { enrollments: serialize_enrollments(enrollments) }, status: :ok
        end

        private

        def require_teacher!
          return if current_user.teacher?

          render json: { error: 'Tylko nauczyciele mogą korzystać z tej funkcji' }, status: :forbidden
        end

        def render_error(message, status)
          render json: { error: message }, status: status
        end

        def already_enrolled?(school)
          TeacherSchoolEnrollment.exists?(teacher: current_user, school: school)
        end

        def render_already_enrolled(school)
          existing = TeacherSchoolEnrollment.find_by(teacher: current_user, school: school)
          render json: {
            error: 'Jesteś już zapisany do tej szkoły',
            status: existing.status,
            school_name: school.name
          }, status: :unprocessable_entity
        end

        def create_enrollment(school)
          enrollment = TeacherSchoolEnrollment.create!(teacher: current_user, school: school,
                                                       status: 'pending')
          update_user_school(school)
          NotificationService.create_teacher_enrollment_request(teacher: current_user, school: school)
          enrollment
        end

        def update_user_school(school)
          current_user.update!(school: school) if current_user.school.nil?
          teacher_role = current_user.user_roles.joins(:role).find_by(roles: { key: 'teacher' })
          teacher_role&.update!(school: school) if teacher_role&.school.nil?
        end

        def render_enrollment_created(enrollment, school)
          render json: {
            success: true, message: 'Wniosek o dołączenie do szkoły został wysłany',
            enrollment_id: enrollment.id, school_name: school.name,
            status: 'pending'
          }, status: :created
        end

        def cancel_enrollment(enrollment)
          school = enrollment.school
          enrollment.destroy!
          NotificationService.resolve_teacher_enrollment_request(teacher: current_user, school: school)
        end

        def serialize_enrollments(enrollments)
          enrollments.map do |e|
            { id: e.id, school_name: e.school.name, status: e.status, created_at: e.created_at }
          end
        end
      end
    end
  end
end
