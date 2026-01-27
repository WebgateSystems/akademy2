# frozen_string_literal: true

module Api
  module V1
    module Teacher
      class DashboardController < ApplicationApiController
        before_action :authorize_access_request!
        before_action :require_teacher!

        # GET /api/v1/teacher/dashboard
        def index
          @classes = current_user.assigned_classes
                                 .includes(:student_class_enrollments, :students)
                                 .where(school_id: current_user.school_id)
                                 .order(:name)

          render json: {
            success: true,
            data: {
              teacher: teacher_data,
              school: school_data,
              classes: classes_data,
              current_class: current_class_data,
              subjects: subjects_data
            }
          }
        end

        # GET /api/v1/teacher/dashboard/class/:id
        def show_class
          @school_class = current_user.assigned_classes.find(params[:id])

          render json: {
            success: true,
            data: {
              class: class_detail_data(@school_class),
              students: students_data(@school_class),
              subjects: subjects_with_results(@school_class)
            }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: 'Class not found' }, status: :not_found
        end

        private

        def require_teacher!
          return if current_user.teacher?

          render json: { success: false, error: 'Unauthorized - teacher access required' }, status: :forbidden
        end

        def teacher_data
          {
            id: current_user.id,
            first_name: current_user.first_name,
            last_name: current_user.last_name,
            email: current_user.email
          }
        end

        def school_data
          school = current_user.school
          return nil unless school

          {
            id: school.id,
            name: school.name,
            address: school.address,
            phone: school.phone,
            email: school.email,
            slug: school.slug,
            current_academic_year: school.current_academic_year_value
          }
        end

        def classes_data
          @classes.map do |school_class|
            {
              id: school_class.id,
              name: school_class.name,
              students_count: school_class.students.count,
              students_awaiting: school_class.student_class_enrollments.where(status: 'pending').count
            }
          end
        end

        def current_class_data
          return nil if @classes.empty?

          first_class = @classes.first
          class_detail_data(first_class)
        end

        def class_detail_data(school_class)
          academic_year = current_user.school&.current_academic_year_value
          {
            id: school_class.id,
            name: school_class.name,
            academic_year: academic_year,
            students_count: school_class.students.count,
            students_awaiting: school_class.student_class_enrollments.where(status: 'pending').count,
            videos_count: videos_count_for_class(school_class),
            videos_awaiting: 0 # Placeholder - implement when video approval is added
          }
        end

        def students_data(school_class)
          school_class.students.map do |student|
            enrollment = student.student_class_enrollments.find_by(school_class: school_class)
            {
              id: student.id,
              first_name: student.first_name,
              last_name: student.last_name,
              email: student.email,
              status: enrollment&.status || 'unknown',
              confirmed: student.confirmed_at.present?
            }
          end
        end

        def subjects_data
          Subject.where(school_id: [nil, current_user.school_id])
                 .includes(units: { learning_modules: :contents })
                 .order(:order_index)
                 .map do |subject|
            {
              id: subject.id,
              title: subject.title,
              slug: subject.slug,
              description: subject.description,
              icon_url: subject.icon.presence&.url,
              color_light: subject.color_light,
              color_dark: subject.color_dark
            }
          end
        end

        def subjects_with_results(school_class)
          student_ids = school_class.students.pluck(:id)

          Subject.where(school_id: [nil, current_user.school_id])
                 .includes(units: :learning_modules)
                 .order(:order_index)
                 .map do |subject|
            module_ids = subject.units.flat_map { |u| u.learning_modules.pluck(:id) }

            total_possible = student_ids.count * module_ids.count
            completed = QuizResult.where(user_id: student_ids, learning_module_id: module_ids).count

            avg_score = if total_possible.positive?
                          QuizResult.where(user_id: student_ids, learning_module_id: module_ids)
                                    .average(:score)&.round || 0
                        else
                          0
                        end

            completion_rate = total_possible.positive? ? ((completed.to_f / total_possible) * 100).round : 0

            {
              id: subject.id,
              title: subject.title,
              slug: subject.slug,
              description: subject.description,
              icon_url: subject.icon.presence&.url,
              color_light: subject.color_light,
              color_dark: subject.color_dark,
              completion_rate: completion_rate,
              average_score: avg_score
            }
          end
        end

        def videos_count_for_class(school_class)
          # Count videos watched by students in this class
          student_ids = school_class.students.pluck(:id)
          Event.where(event_type: 'video_view', user_id: student_ids).select(:user_id).distinct.count
        end
      end
    end
  end
end
