# frozen_string_literal: true

module Management
  class ReportsController < BaseController
    MODULES_TO_PASS = 7

    def index
      @school = current_school_manager.school
      return redirect_to management_root_path, alert: t('management.errors.no_school_assigned') unless @school

      load_summary_stats
      load_classes_breakdown

      respond_to do |format|
        format.html
        format.pdf { render_pdf }
      end
    end

    def class_certificates
      @school = current_school_manager.school
      school_class = @school.school_classes.find(params[:id])
      enrolled_ids = school_class.student_class_enrollments.where(status: 'approved').pluck(:student_id)
      students_data = build_students_with_certs(enrolled_ids)

      render json: { students: students_data }
    end

    private

    def load_summary_stats
      @student_role = Role.find_by(key: 'student')
      @teacher_role = Role.find_by(key: 'teacher')

      @teachers_count = UserRole.where(school_id: @school.id, role_id: @teacher_role&.id).count
      @classes_count = @school.school_classes.count
      @students_count = UserRole.where(school_id: @school.id, role_id: @student_role&.id).count
      @total_certificates_count = certificates_count_for(school_student_ids)
      @report_generated_at = Time.current
    end

    def load_classes_breakdown
      @class_rows = build_class_rows
      @class_rows_with_certs = @class_rows.select { |r| r[:certificates_count].positive? }
      @show_classes_breakdown = @class_rows_with_certs.present?
    end

    def school_student_ids
      @school_student_ids ||= UserRole.where(school_id: @school.id, role_id: @student_role&.id).pluck(:user_id)
    end

    def build_class_rows
      @school.school_classes.order(:name).map { |sc| build_class_row(sc) }
    end

    def build_class_row(school_class)
      enrolled_ids = school_class.student_class_enrollments.where(status: 'approved').pluck(:student_id)
      certs = certificates_count_for(enrolled_ids)
      students_count = enrolled_ids.size
      max_certs = [students_count * MODULES_TO_PASS, 1].max

      { class_id: school_class.id, class_name: school_class.name, students_count: students_count,
        certificates_count: certs, percentage: (certs.to_f / max_certs * 100).round(1) }
    end

    def build_students_with_certs(student_ids)
      return [] if student_ids.empty?

      all_certs = Certificate.joins(quiz_result: :learning_module)
                             .where(quiz_results: { user_id: student_ids })
                             .includes(quiz_result: [:learning_module, { user: :school }])
                             .order('learning_modules.id')

      certs_by_user = all_certs.group_by { |c| c.quiz_result.user_id }

      user_ids_with_certs = certs_by_user.keys
      students = User.where(id: user_ids_with_certs).order(:last_name, :first_name)

      students.map do |student|
        user_certs = certs_by_user[student.id] || []
        {
          student_name: "#{student.last_name} #{student.first_name}",
          certificates: user_certs.map { |c| certificate_data(c) }
        }
      end
    end

    def certificate_data(cert)
      { id: cert.id, module_title: cert.learning_module&.title, pdf_url: cert.pdf&.url }
    end

    def certificates_count_for(user_ids)
      return 0 if user_ids.blank?

      Certificate.joins(:quiz_result).where(quiz_results: { user_id: user_ids }).count
    end

    def render_pdf
      render pdf: pdf_filename_without_ext,
             template: 'management/reports/index',
             layout: 'layouts/management_report_pdf',
             formats: [:html],
             disposition: 'inline',
             margin: { top: 12, bottom: 12, left: 12, right: 12 }
    end

    def pdf_filename_without_ext
      school_slug = @school.name.parameterize
      "raport-#{school_slug}-#{@report_generated_at.strftime('%Y-%m-%d-%H%M')}"
    end
  end
end
