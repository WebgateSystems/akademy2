# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CertificatesController, type: :request do
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:school) { create(:school) }
  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end

  let!(:subject_record) { create(:subject, school: nil, title: 'Test Subject', slug: 'test-subject') }
  let!(:unit) { create(:unit, subject: subject_record, title: 'Unit 1', order_index: 1) }
  let!(:learning_module) do
    create(:learning_module, unit: unit, title: 'Test Module', slug: 'test-module', published: true)
  end

  let!(:quiz_result) do
    QuizResult.create!(
      user: student,
      learning_module: learning_module,
      score: 100,
      passed: true,
      details: { 'correct_count' => 10, 'total' => 10 },
      completed_at: Time.current
    )
  end

  let!(:certificate) { create(:certificate, quiz_result: quiz_result) }

  describe 'GET /certificates/:id' do
    context 'when certificate exists' do
      it 'renders certificate page without authentication' do
        get public_certificate_path(certificate)

        expect(response).to have_http_status(:success)
      end

      it 'displays student name' do
        get public_certificate_path(certificate)

        expect(response.body).to include(student.first_name)
        # Last names can be HTML-escaped in the response (e.g. apostrophe -> &#39;)
        escaped_last_name = ERB::Util.h(student.last_name)
        expect(response.body).to(satisfy do |body|
          body.include?(student.last_name) || body.include?(escaped_last_name)
        end)
      end

      it 'displays module title' do
        get public_certificate_path(certificate)

        expect(response.body).to include(learning_module.title)
      end

      it 'displays quiz score' do
        get public_certificate_path(certificate)

        expect(response.body).to include('100%')
      end

      it 'displays issue date' do
        get public_certificate_path(certificate)

        expect(response.body).to include(certificate.created_at.strftime('%d.%m.%Y'))
      end
    end

    context 'when certificate does not exist' do
      it 'returns not found' do
        get public_certificate_path(id: 'non-existent-uuid')

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when requesting PDF format' do
      it 'serves PDF file' do
        get public_certificate_path(certificate, format: :pdf)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/pdf')
      end

      it 'sets correct filename' do
        get public_certificate_path(certificate, format: :pdf)

        expect(response.headers['Content-Disposition']).to include("certificate-#{certificate.id}.pdf")
      end
    end

    context 'when PDF file is missing' do
      before do
        allow_any_instance_of(Certificate).to receive(:pdf).and_return(nil)
      end

      it 'returns not found for PDF format' do
        get public_certificate_path(certificate, format: :pdf)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
