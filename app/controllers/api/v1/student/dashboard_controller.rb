# frozen_string_literal: true

module Api
  module V1
    module Student
      class DashboardController < ApplicationApiController
        before_action :authorize_access_request!
        before_action :require_student!

        # GET /api/v1/student/dashboard
        # Returns student's subjects with progress
        def index
          school = current_user.school
          classes = approved_classes

          subjects = Subject.where(school_id: [nil, school&.id])
                            .includes(units: :learning_modules)
                            .order(:order_index)

          render json: {
            success: true,
            data: {
              student: student_data,
              school: school_data(school),
              classes: classes_data(classes),
              subjects: subjects_with_progress(subjects)
            }
          }
        end

        # GET /api/v1/student/subjects/:id
        # Returns subject details with modules and contents
        def show_subject
          subject = Subject.where(school_id: [nil, current_user.school_id])
                           .includes(units: { learning_modules: :contents })
                           .find(params[:id])

          render json: {
            success: true,
            data: {
              subject: subject_detail(subject),
              units: units_with_modules(subject),
              progress: subject_progress(subject)
            }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: 'Subject not found' }, status: :not_found
        end

        # GET /api/v1/student/learning_modules/:id
        # Returns module with all contents for learning flow
        def show_module
          learning_module = LearningModule.includes(:contents, :unit)
                                          .find(params[:id])

          # Verify student has access to this module's subject
          subject = learning_module.unit.subject
          unless subject.school_id.nil? || subject.school_id == current_user.school_id
            return render json: { success: false, error: 'Access denied' }, status: :forbidden
          end

          render json: {
            success: true,
            data: {
              module: module_detail(learning_module),
              contents: module_contents(learning_module),
              quiz: quiz_data(learning_module),
              previous_result: previous_quiz_result(learning_module)
            }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: 'Module not found' }, status: :not_found
        end

        private

        def require_student!
          return if current_user.student?

          render json: { success: false, error: 'Student access required' }, status: :forbidden
        end

        def approved_classes
          current_user.school_classes.where(
            id: StudentClassEnrollment.where(student: current_user, status: 'approved').select(:school_class_id)
          ).order(:name)
        end

        def student_data
          {
            id: current_user.id,
            first_name: current_user.first_name,
            last_name: current_user.last_name,
            email: current_user.email
          }
        end

        def school_data(school)
          return nil unless school

          {
            id: school.id,
            name: school.name,
            logo_url: school.logo&.url
          }
        end

        def classes_data(classes)
          classes.map do |klass|
            {
              id: klass.id,
              name: klass.name,
              year: klass.year
            }
          end
        end

        def subjects_with_progress(subjects)
          subjects.map do |subject|
            module_ids = subject.units.flat_map { |u| u.learning_modules.pluck(:id) }
            quiz_results = QuizResult.where(user_id: current_user.id, learning_module_id: module_ids)

            total_modules = module_ids.count
            completed = quiz_results.where(passed: true).count

            {
              id: subject.id,
              title: subject.title,
              slug: subject.slug,
              icon_url: subject.icon&.url,
              color_light: subject.color_light,
              color_dark: subject.color_dark,
              total_modules: total_modules,
              completed_modules: completed,
              completion_rate: total_modules.positive? ? ((completed.to_f / total_modules) * 100).round : 0,
              average_score: quiz_results.average(:score)&.round || 0
            }
          end
        end

        def subject_detail(subject)
          {
            id: subject.id,
            title: subject.title,
            slug: subject.slug,
            icon_url: subject.icon&.url,
            color_light: subject.color_light,
            color_dark: subject.color_dark
          }
        end

        def units_with_modules(subject)
          subject.units.order(:order_index).map do |unit|
            {
              id: unit.id,
              title: unit.title,
              order_index: unit.order_index,
              modules: unit.learning_modules.where(published: true).order(:order_index).map do |lm|
                quiz_result = QuizResult.find_by(user_id: current_user.id, learning_module_id: lm.id)
                {
                  id: lm.id,
                  title: lm.title,
                  order_index: lm.order_index,
                  contents_count: lm.contents.count,
                  completed: quiz_result&.passed || false,
                  score: quiz_result&.score
                }
              end
            }
          end
        end

        def subject_progress(subject)
          module_ids = subject.units.flat_map { |u| u.learning_modules.where(published: true).pluck(:id) }
          quiz_results = QuizResult.where(user_id: current_user.id, learning_module_id: module_ids)

          {
            total_modules: module_ids.count,
            completed_modules: quiz_results.where(passed: true).count,
            average_score: quiz_results.average(:score)&.round || 0
          }
        end

        def module_detail(learning_module)
          {
            id: learning_module.id,
            title: learning_module.title,
            unit_id: learning_module.unit_id,
            unit_title: learning_module.unit.title,
            single_flow: learning_module.single_flow
          }
        end

        def module_contents(learning_module)
          learning_module.contents.order(:order_index).map do |content|
            {
              id: content.id,
              title: content.title,
              content_type: content.content_type,
              order_index: content.order_index,
              file_url: content.file&.url,
              poster_url: content.poster&.url,
              subtitles_url: content.subtitles&.url,
              youtube_url: content.youtube_url,
              duration_sec: content.duration_sec,
              payload: content.payload
            }
          end
        end

        def quiz_data(learning_module)
          # Quiz questions are stored in content with type 'quiz'
          quiz_content = learning_module.contents.find_by(content_type: 'quiz')
          return nil unless quiz_content

          {
            id: quiz_content.id,
            title: quiz_content.title,
            questions: quiz_content.payload['questions'] || [],
            pass_threshold: 80
          }
        end

        def previous_quiz_result(learning_module)
          result = QuizResult.find_by(user_id: current_user.id, learning_module_id: learning_module.id)
          return nil unless result

          {
            id: result.id,
            score: result.score,
            passed: result.passed,
            completed_at: result.completed_at,
            details: result.details
          }
        end
      end
    end
  end
end
