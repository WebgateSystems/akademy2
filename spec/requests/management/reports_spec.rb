# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Management reports', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }

  let(:school) { create(:school) }
  let(:principal) do
    user = create(:user, school: school, confirmed_at: Time.current)
    UserRole.create!(user: user, role: principal_role, school: school)
    user.reload
  end

  before do
    principal_role
    school_manager_role
    sign_in principal
    # Stub WickedPdf to avoid "Location of wkhtmltopdf unknown" on CI
    allow(WickedPdf).to receive(:new).and_return(instance_double(WickedPdf, pdf_from_string: '%PDF-1.4'))
  end

  describe 'GET /management/reports' do
    it 'returns success' do
      get management_reports_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders report page with stats' do
      get management_reports_path
      expect(response.body).to include(I18n.t('admin.reports.title'))
      expect(response.body).to include(I18n.t('admin.reports.generated_at', datetime: '').split('%').first)
    end

    it 'renders export dropdown when HTML' do
      get management_reports_path
      expect(response.body).to include(I18n.t('admin.reports.export'))
      expect(response.body).to include(management_export_reports_pdf_path)
    end

    it 'shows stats cards' do
      get management_reports_path
      expect(response.body).to include(I18n.t('admin.reports.stats.teachers'))
      expect(response.body).to include(I18n.t('admin.reports.stats.classes'))
      expect(response.body).to include(I18n.t('admin.reports.stats.students'))
      expect(response.body).to include(I18n.t('admin.reports.stats.certificates'))
    end
  end

  describe 'GET /management/reports/export.pdf' do
    it 'returns PDF with inline disposition' do
      get management_export_reports_pdf_path
      expect(response).to have_http_status(:success)
      expect(response.media_type).to include('application/pdf')
      expect(response.body).to start_with('%PDF')
      expect(response.headers['Content-Disposition']).to include('inline')
    end

    it 'includes school slug in filename' do
      get management_export_reports_pdf_path
      expect(response.headers['Content-Disposition']).to include(school.name.parameterize)
    end
  end

  describe 'GET /management/reports/class_certificates/:id' do
    let(:school_class) { create(:school_class, school: school, name: '4A') }
    let(:subject_record) { create(:subject, school: school) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit, title: 'Test Module') }
    let(:student) do
      user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
      UserRole.create!(user: user, role: student_role, school: school)
      StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
      user
    end

    it 'returns JSON with students and certificates' do
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      get management_class_certificates_path(school_class), headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('application/json')
      json = response.parsed_body
      expect(json['students']).to be_an(Array)
      expect(json['students'].first['student_name']).to eq('Kowalski Jan')
    end

    it 'returns empty array when class has no certificates' do
      student # create student without certificates
      get management_class_certificates_path(school_class), headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json['students']).to eq([])
    end

    it 'returns 404 for class from another school' do
      other_school = create(:school)
      other_class = create(:school_class, school: other_school, name: '5A')
      get management_class_certificates_path(other_class), headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when not authenticated' do
    before { sign_out principal }

    it 'redirects to login page for reports index' do
      get management_reports_path
      expect(response).to redirect_to(administration_login_path)
    end

    it 'redirects to login page for PDF export' do
      get management_export_reports_pdf_path
      expect(response).to redirect_to(administration_login_path)
    end
  end

  context 'when user has no school' do
    before do
      principal.update!(school: nil)
    end

    it 'redirects to management root with alert' do
      get management_reports_path
      expect(response).to redirect_to(management_root_path)
      expect(flash[:alert]).to eq(I18n.t('management.errors.no_school_assigned'))
    end
  end
end
