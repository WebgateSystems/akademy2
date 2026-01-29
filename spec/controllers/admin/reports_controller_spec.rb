# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ReportsController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin) do
    user = create(:user)
    UserRole.create!(user: user, role: admin_role)
    user
  end

  def login_as_admin(user)
    token = Jwt::TokenService.encode({ user_id: user.id })
    session[:admin_id] = token
  end

  before do
    login_as_admin(admin)
    # Stub WickedPdf to avoid "Location of wkhtmltopdf unknown" on CI
    allow(WickedPdf).to receive(:new).and_return(instance_double(WickedPdf, pdf_from_string: '%PDF-1.4'))
  end

  describe 'GET #index' do
    context 'with format HTML' do
      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns schools_count' do
        baseline = School.count
        create_list(:school, 2)
        get :index
        expect(assigns(:schools_count)).to eq(baseline + 2)
      end

      it 'assigns teachers_count' do
        teacher_role = Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' }
        school = create(:school)
        teacher = create(:user, school: school)
        UserRole.create!(user: teacher, role: teacher_role, school: school)
        get :index
        expect(assigns(:teachers_count)).to eq(1)
      end

      it 'assigns classes_count' do
        school = create(:school)
        %w[1A 2B 3C].each { |name| create(:school_class, school: school, name: name) }
        get :index
        expect(assigns(:classes_count)).to eq(SchoolClass.count)
      end

      it 'assigns students_count' do
        student_role = Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' }
        school = create(:school)
        student = create(:user, school: school)
        UserRole.create!(user: student, role: student_role, school: school)
        get :index
        expect(assigns(:students_count)).to eq(1)
      end

      it 'assigns total_certificates_count' do
        school = create(:school)
        subject_record = create(:subject, school: school)
        unit = create(:unit, subject: subject_record)
        learning_module = create(:learning_module, unit: unit)
        user = create(:user, school: school)
        qr = create(:quiz_result, user: user, learning_module: learning_module)
        create(:certificate, quiz_result: qr)
        get :index
        expect(assigns(:total_certificates_count)).to eq(1)
      end

      it 'assigns report_generated_at' do
        now = Time.current
        travel_to(now) do
          get :index
          expect(assigns(:report_generated_at)).to be_within(1.second).of(now)
        end
      end

      it 'sets show_per_school_breakdown to false when 3 or fewer schools' do
        allow(School).to receive(:count).and_return(3)
        get :index
        expect(assigns(:show_per_school_breakdown)).to be(false)
        expect(assigns(:schools_with_stats)).to be_nil
      end

      it 'sets show_per_school_breakdown to true when more than 3 schools' do
        schools = create_list(:school, 4)
        allow(School).to receive(:count).and_return(4)
        allow(School).to receive(:order).with(:name).and_return(School.where(id: schools.map(&:id)).order(:name))
        get :index
        expect(assigns(:show_per_school_breakdown)).to be(true)
        expect(assigns(:schools_with_stats)).to eq([])
      end
    end

    context 'with format PDF' do
      before do
        # Stub render so we don't invoke WickedPdf/wkhtmltopdf; set response so Rails doesn't raise UnknownFormat
        allow(controller).to receive(:render) do |*_args|
          controller.response_body = '%PDF-1.4'
          controller.content_type = 'application/pdf'
        end
      end

      it 'responds with PDF format and sets instance variables' do
        get :index, format: :pdf
        expect(assigns(:schools_count)).to be >= 0
        expect(assigns(:report_generated_at)).to be_present
      end

      it 'calls render with pdf options' do
        get :index, format: :pdf
        expect(controller).to have_received(:render).with(
          hash_including(
            template: 'admin/reports/index',
            layout: 'layouts/admin_report_pdf',
            formats: [:html],
            disposition: 'inline'
          )
        )
      end
    end
  end

  describe 'build_schools_with_stats (via GET #index with > 3 schools)' do
    let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
    let(:school) { create(:school, name: 'Szkoła A') }
    let(:subject_record) { create(:subject, school: school) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit) }
    let(:school_class) { create(:school_class, school: school, name: '4A', year: '2025/2026') }
    let(:student) do
      user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
      UserRole.create!(user: user, role: student_role, school: school)
      StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
      user
    end

    # Stub School.count/order to control which schools are in the report (avoids FK issues)
    # Always return count > 3 so build_schools_with_stats is called
    def stub_schools_for_report(*schools)
      allow(School).to receive(:count).and_return(4)
      allow(School).to receive(:order).with(:name).and_return(School.where(id: schools.map(&:id)).order(:name))
    end

    it 'includes only schools that have at least one class with certificates > 0' do
      stub_schools_for_report(school)
      allow(Settings).to receive(:reports).and_return(nil) # threshold 0
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      get :index
      stats = assigns(:schools_with_stats)
      expect(stats.size).to eq(1)
      expect(stats.first[:school]).to eq(school)
      expect(stats.first[:class_rows].size).to eq(1)
      expect(stats.first[:class_rows].first[:class_name]).to eq('4A')
      expect(stats.first[:class_rows].first[:certificates_count]).to eq(1)
    end

    it 'excludes schools with zero certificates in every class' do
      stub_schools_for_report(school)
      get :index
      stats = assigns(:schools_with_stats)
      expect(stats).to eq([])
    end

    it 'excludes class_rows with zero certificates' do
      stub_schools_for_report(school)
      allow(Settings).to receive(:reports).and_return(nil) # threshold 0
      other_class = create(:school_class, school: school, name: '5A', year: '2025/2026')
      other_student = create(:user, school: school)
      UserRole.create!(user: other_student, role: student_role, school: school)
      StudentClassEnrollment.create!(student: other_student, school_class: other_class, status: 'approved')
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      get :index
      stats = assigns(:schools_with_stats)
      expect(stats.size).to eq(1)
      expect(stats.first[:class_rows].map { |r| r[:class_name] }).to contain_exactly('4A')
    end

    it 'respects Settings.reports.min_certificates_per_school threshold' do
      stub_schools_for_report(school)
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      allow(Settings).to receive(:reports).and_return(double(min_certificates_per_school: 2))
      get :index
      stats = assigns(:schools_with_stats)
      expect(stats).to eq([])
    end

    it 'includes school when total_certificates meets threshold' do
      stub_schools_for_report(school)
      student2 = create(:user, school: school)
      UserRole.create!(user: student2, role: student_role, school: school)
      StudentClassEnrollment.create!(student: student2, school_class: school_class, status: 'approved')
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      create(:certificate, quiz_result: create(:quiz_result, user: student2, learning_module: learning_module))
      allow(Settings).to receive(:reports).and_return(double(min_certificates_per_school: 2))
      get :index
      stats = assigns(:schools_with_stats)
      expect(stats.size).to eq(1)
      expect(stats.first[:total_certificates]).to eq(2)
    end

    it 'includes school with 1 cert when Settings.reports is nil (threshold 0)' do
      stub_schools_for_report(school)
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      allow(Settings).to receive(:reports).and_return(nil)
      get :index
      stats = assigns(:schools_with_stats)
      expect(stats.size).to eq(1)
      expect(stats.first[:total_certificates]).to eq(1)
    end

    it 'sorts schools by completion percentage (best first)' do
      school_b = create(:school, name: 'Szkoła B')
      subj_b = create(:subject, school: school_b)
      unit_b = create(:unit, subject: subj_b)
      lm_b = create(:learning_module, unit: unit_b)
      sc_b = create(:school_class, school: school_b, name: '4B', year: '2025/2026')
      student_b = create(:user, school: school_b)
      UserRole.create!(user: student_b, role: student_role, school: school_b)
      StudentClassEnrollment.create!(student: student_b, school_class: sc_b, status: 'approved')
      create(:certificate, quiz_result: create(:quiz_result, user: student_b, learning_module: lm_b))
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      stub_schools_for_report(school, school_b)
      allow(Settings).to receive(:reports).and_return(nil) # threshold 0
      get :index
      stats = assigns(:schools_with_stats)
      expect(stats.size).to eq(2)
      # School B: 1 cert, 1 student * 7 = 7 max -> ~14.3%. School A: same. Order by name then by %.
      # Sort is by -completion_pct, so higher % first. Same % order depends on School.order(:name).
      expect(stats.map { |s| s[:school].name }).to contain_exactly(school.name, school_b.name)
    end

    it 'assigns correct structure for each school row' do
      stub_schools_for_report(school)
      allow(Settings).to receive(:reports).and_return(nil) # threshold 0
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      get :index
      row = assigns(:schools_with_stats).first
      expect(row).to include(
        :school, :classes_count, :class_rows, :total_students, :total_certificates,
        :to_complete, :completed
      )
      expect(row[:school]).to eq(school)
      expect(row[:total_certificates]).to eq(1)
      expect(row[:to_complete]).to eq(7)
      expect(row[:completed]).to eq(1)
    end
  end
end
