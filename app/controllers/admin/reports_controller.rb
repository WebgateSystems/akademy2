# frozen_string_literal: true

class Admin::ReportsController < Admin::BaseController
  MODULES_TO_PASS = 7

  def index
    load_summary_stats
    load_schools_breakdown

    respond_to do |format|
      format.html
      format.pdf { render_pdf }
    end
  end

  def class_certificates
    school_class = SchoolClass.find(params[:id])
    enrolled_ids = school_class.student_class_enrollments.where(status: 'approved').pluck(:student_id)
    students_data = build_students_with_certs(enrolled_ids)

    render json: { students: students_data }
  end

  private

  def load_summary_stats
    @schools_count = School.count
    @teachers_count = User.joins(:roles).where(roles: { key: 'teacher' }).distinct.count
    @classes_count = SchoolClass.count
    @students_count = User.joins(:roles).where(roles: { key: 'student' }).distinct.count
    @total_certificates_count = Certificate.count
    @report_generated_at = Time.current
  end

  def load_schools_breakdown
    @show_per_school_breakdown = @schools_count > 3
    @schools_with_stats = build_schools_with_stats if @show_per_school_breakdown
  end

  def render_pdf
    render pdf: pdf_filename_without_ext,
           template: 'admin/reports/index',
           layout: 'layouts/admin_report_pdf',
           formats: [:html],
           disposition: 'inline',
           margin: { top: 12, bottom: 12, left: 12, right: 12 }
  end

  def build_schools_with_stats
    @student_role = Role.find_by(key: 'student')
    return [] unless @student_role

    School.order(:name).filter_map { |school| build_school_row(school) }.sort_by do |row|
      -completion_percentage(row)
    end
  end

  def build_school_row(school)
    school_student_ids = school_student_ids_for(school)
    class_rows = build_class_rows(school)
    total_certs = certificates_count_for(school_student_ids)

    class_rows_with_certs = class_rows.select { |r| r[:certificates_count].positive? }
    return nil if class_rows_with_certs.empty?
    return nil if below_min_certificates_threshold?(total_certs)

    build_school_hash(school, class_rows, class_rows_with_certs, total_certs)
  end

  def school_student_ids_for(school)
    UserRole.where(school_id: school.id, role_id: @student_role.id).pluck(:user_id)
  end

  def build_class_rows(school)
    SchoolClass.where(school_id: school.id).order(:name).map { |sc| build_class_row(sc) }
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

    # Load all certificates with eager loading for PDF URL generation
    all_certs = Certificate.joins(quiz_result: :learning_module)
                           .where(quiz_results: { user_id: student_ids })
                           .includes(quiz_result: [:learning_module, { user: :school }])
                           .order('learning_modules.id')

    # Group certificates by user_id
    certs_by_user = all_certs.group_by { |c| c.quiz_result.user_id }

    # Get users who have certificates, sorted alphabetically
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
    Certificate.joins(:quiz_result).where(quiz_results: { user_id: user_ids }).count
  end

  def below_min_certificates_threshold?(total_certs)
    min_certs = (Settings.reports&.min_certificates_per_school || 0).to_i
    min_certs.positive? && total_certs < min_certs
  end

  def build_school_hash(school, all_class_rows, class_rows_with_certs, total_certs)
    total_students = all_class_rows.sum { |r| r[:students_count] }
    { school: school, classes_count: all_class_rows.size, class_rows: class_rows_with_certs,
      total_students: total_students, total_certificates: total_certs,
      to_complete: total_students * MODULES_TO_PASS, completed: total_certs }
  end

  def completion_percentage(row)
    max_certs = [row[:to_complete], 1].max
    row[:total_certificates].to_f / max_certs * 100
  end

  def pdf_filename_without_ext
    "raport-#{@report_generated_at.strftime('%Y-%m-%d-%H%M')}"
  end
end
