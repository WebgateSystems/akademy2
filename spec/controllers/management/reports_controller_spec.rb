# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Management::ReportsController, type: :controller do
  include ActiveSupport::Testing::TimeHelpers
  include Devise::Test::ControllerHelpers

  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:principal) do
    user = create(:user, school: school)
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

  describe 'GET #index' do
    context 'with format HTML' do
      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns school' do
        get :index
        expect(assigns(:school)).to eq(school)
      end

      it 'assigns teachers_count for the school only' do
        # Create teacher for our school
        teacher = create(:user, school: school)
        UserRole.create!(user: teacher, role: teacher_role, school: school)

        # Create teacher for another school (should not be counted)
        other_school = create(:school)
        other_teacher = create(:user, school: other_school)
        UserRole.create!(user: other_teacher, role: teacher_role, school: other_school)

        get :index
        expect(assigns(:teachers_count)).to eq(1)
      end

      it 'assigns classes_count for the school only' do
        create(:school_class, school: school, name: '1A')
        create(:school_class, school: school, name: '2B')

        # Create class for another school (should not be counted)
        other_school = create(:school)
        create(:school_class, school: other_school, name: '3C')

        get :index
        expect(assigns(:classes_count)).to eq(2)
      end

      it 'assigns students_count for the school only' do
        student = create(:user, school: school)
        UserRole.create!(user: student, role: student_role, school: school)

        # Create student for another school (should not be counted)
        other_school = create(:school)
        other_student = create(:user, school: other_school)
        UserRole.create!(user: other_student, role: student_role, school: other_school)

        get :index
        expect(assigns(:students_count)).to eq(1)
      end

      it 'assigns total_certificates_count for the school students only' do
        subject_record = create(:subject, school: school)
        unit = create(:unit, subject: subject_record)
        learning_module = create(:learning_module, unit: unit)
        student = create(:user, school: school)
        UserRole.create!(user: student, role: student_role, school: school)
        qr = create(:quiz_result, user: student, learning_module: learning_module)
        create(:certificate, quiz_result: qr)

        # Create certificate for another school (should not be counted)
        other_school = create(:school)
        other_student = create(:user, school: other_school)
        UserRole.create!(user: other_student, role: student_role, school: other_school)
        other_qr = create(:quiz_result, user: other_student, learning_module: learning_module)
        create(:certificate, quiz_result: other_qr)

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

      it 'assigns class_rows for school classes' do
        create(:school_class, school: school, name: '1A')
        create(:school_class, school: school, name: '2B')

        get :index
        expect(assigns(:class_rows).size).to eq(2)
        expect(assigns(:class_rows).map { |r| r[:class_name] }).to contain_exactly('1A', '2B')
      end

      it 'sets show_classes_breakdown to true when there are classes with certificates' do
        school_class = create(:school_class, school: school, name: '1A')
        student = create(:user, school: school)
        UserRole.create!(user: student, role: student_role, school: school)
        StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')

        subject_record = create(:subject, school: school)
        unit = create(:unit, subject: subject_record)
        learning_module = create(:learning_module, unit: unit)
        qr = create(:quiz_result, user: student, learning_module: learning_module)
        create(:certificate, quiz_result: qr)

        get :index
        expect(assigns(:show_classes_breakdown)).to be(true)
        expect(assigns(:class_rows_with_certs).size).to eq(1)
      end

      it 'sets show_classes_breakdown to false when no classes have certificates' do
        create(:school_class, school: school, name: '1A')

        get :index
        expect(assigns(:show_classes_breakdown)).to be(false)
        expect(assigns(:class_rows_with_certs)).to eq([])
      end
    end

    context 'when user has no school' do
      before do
        principal.update!(school: nil)
      end

      it 'redirects to management root with alert' do
        get :index
        expect(response).to redirect_to(management_root_path)
        expect(flash[:alert]).to eq(I18n.t('management.errors.no_school_assigned'))
      end
    end

    context 'with format PDF' do
      before do
        # Stub render so we don't invoke WickedPdf/wkhtmltopdf
        allow(controller).to receive(:render) do |*_args|
          controller.response_body = '%PDF-1.4'
          controller.content_type = 'application/pdf'
        end
      end

      it 'responds with PDF format and sets instance variables' do
        get :index, format: :pdf
        expect(assigns(:school)).to eq(school)
        expect(assigns(:report_generated_at)).to be_present
      end

      it 'calls render with pdf options' do
        get :index, format: :pdf
        expect(controller).to have_received(:render).with(
          hash_including(
            template: 'management/reports/index',
            layout: 'layouts/management_report_pdf',
            formats: [:html],
            disposition: 'inline'
          )
        )
      end

      it 'includes school slug in pdf filename' do
        get :index, format: :pdf
        expect(controller).to have_received(:render).with(
          hash_including(pdf: a_string_matching(/raport-#{school.name.parameterize}/))
        )
      end
    end
  end

  describe 'GET #class_certificates' do
    let(:school_class) { create(:school_class, school: school, name: '4A') }
    let(:subject_record) { create(:subject, school: school) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit, title: 'Moduł 1') }
    let(:learning_module_2) { create(:learning_module, unit: unit, title: 'Moduł 2') }
    let(:student) do
      user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
      UserRole.create!(user: user, role: student_role, school: school)
      StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
      user
    end

    it 'returns JSON with students and certificates' do
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      get :class_certificates, params: { id: school_class.id }, format: :json
      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json['students']).to be_an(Array)
      expect(json['students'].size).to eq(1)
      expect(json['students'].first['student_name']).to eq('Kowalski Jan')
      expect(json['students'].first['certificates'].size).to eq(1)
      expect(json['students'].first['certificates'].first['module_title']).to eq('Moduł 1')
    end

    it 'returns empty students array when no certificates' do
      student
      get :class_certificates, params: { id: school_class.id }, format: :json
      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json['students']).to eq([])
    end

    it 'orders students by last name, first name' do
      student_a = create(:user, school: school, first_name: 'Anna', last_name: 'Adamska')
      student_z = create(:user, school: school, first_name: 'Zofia', last_name: 'Zielińska')
      UserRole.create!(user: student_a, role: student_role, school: school)
      UserRole.create!(user: student_z, role: student_role, school: school)
      StudentClassEnrollment.create!(student: student_a, school_class: school_class, status: 'approved')
      StudentClassEnrollment.create!(student: student_z, school_class: school_class, status: 'approved')
      create(:certificate, quiz_result: create(:quiz_result, user: student_a, learning_module: learning_module))
      create(:certificate, quiz_result: create(:quiz_result, user: student_z, learning_module: learning_module))

      get :class_certificates, params: { id: school_class.id }, format: :json
      json = response.parsed_body
      names = json['students'].map { |s| s['student_name'] }
      expect(names).to eq(['Adamska Anna', 'Zielińska Zofia'])
    end

    it 'orders certificates by learning module id' do
      lm1 = learning_module
      lm2 = learning_module_2
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: lm2))
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: lm1))

      get :class_certificates, params: { id: school_class.id }, format: :json
      json = response.parsed_body
      cert_ids = json['students'].first['certificates'].map { |c| c['id'] }

      expected_order = [lm1, lm2].sort_by(&:id).map do |lm|
        Certificate.joins(:quiz_result).find_by(quiz_results: { learning_module_id: lm.id }).id
      end
      expect(cert_ids).to eq(expected_order)
    end

    it 'includes pdf_url for certificates' do
      create(:certificate, quiz_result: create(:quiz_result, user: student, learning_module: learning_module))
      get :class_certificates, params: { id: school_class.id }, format: :json
      json = response.parsed_body
      expect(json['students'].first['certificates'].first).to have_key('pdf_url')
    end

    it 'returns 404 for class from another school' do
      other_school = create(:school)
      other_class = create(:school_class, school: other_school, name: '5A')
      expect do
        get :class_certificates, params: { id: other_class.id }, format: :json
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns 404 for non-existent class' do
      expect do
        get :class_certificates, params: { id: 'non-existent-id' }, format: :json
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
