# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Student::EnrollmentsController, type: :controller do
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, school: school) }
  let(:student_role) { Role.find_or_create_by!(key: 'student', name: 'Student') }
  let(:student) { create(:user, school: school) }

  before do
    student.roles << student_role unless student.roles.include?(student_role)
    sign_in student
  end

  describe 'POST #join' do
    context 'with valid token' do
      it 'creates a pending enrollment' do
        expect do
          post :join, params: { token: school_class.join_token }, format: :json
        end.to change(StudentClassEnrollment, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['status']).to eq('pending')
      end

      it 'creates notification for teachers' do
        teacher = create(:user)
        teacher_role = Role.find_or_create_by!(key: 'teacher', name: 'Teacher')
        teacher.roles << teacher_role
        create(:teacher_class_assignment, teacher: teacher, school_class: school_class)

        expect do
          post :join, params: { token: school_class.join_token }, format: :json
        end.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.notification_type).to eq('student_enrollment_request')
        expect(notification.target_role).to eq('teacher')
      end

      it 'updates student school if not set' do
        student.update!(school: nil)

        post :join, params: { token: school_class.join_token }, format: :json

        student.reload
        expect(student.school).to eq(school)
      end
    end

    context 'with URL containing token' do
      it 'extracts token from URL and creates enrollment' do
        url = "http://localhost:3000/join/class/#{school_class.join_token}"

        expect do
          post :join, params: { token: url }, format: :json
        end.to change(StudentClassEnrollment, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid token' do
      it 'returns not found' do
        post :join, params: { token: 'invalid-token-here' }, format: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Nieprawidłowy token klasy')
      end
    end

    context 'when already enrolled' do
      before do
        create(:student_class_enrollment, student: student, school_class: school_class, status: 'pending')
      end

      it 'returns error' do
        post :join, params: { token: school_class.join_token }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Jesteś już zapisany do tej klasy')
      end
    end

    context 'without token' do
      it 'returns error' do
        post :join, params: {}, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Token jest wymagany')
      end
    end

    context 'when not a student' do
      let(:teacher) { create(:user) }

      before do
        teacher_role = Role.find_or_create_by!(key: 'teacher', name: 'Teacher')
        teacher.roles << teacher_role
        sign_in teacher
      end

      it 'returns forbidden' do
        post :join, params: { token: school_class.join_token }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #cancel' do
    let!(:enrollment) do
      create(:student_class_enrollment, student: student, school_class: school_class, status: 'pending')
    end

    context 'with pending enrollment' do
      it 'destroys the enrollment' do
        expect do
          delete :cancel, params: { id: enrollment.id }, format: :json
        end.to change(StudentClassEnrollment, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
      end

      it 'resolves notification' do
        teacher = create(:user)
        teacher_role = Role.find_or_create_by!(key: 'teacher', name: 'Teacher')
        teacher.roles << teacher_role
        create(:teacher_class_assignment, teacher: teacher, school_class: school_class)

        # Create notification first
        NotificationService.create_student_enrollment_request(student: student, school_class: school_class)
        notification = Notification.last
        expect(notification.resolved_at).to be_nil

        delete :cancel, params: { id: enrollment.id }, format: :json

        notification.reload
        expect(notification.resolved_at).to be_present
      end
    end

    context 'with approved enrollment' do
      before { enrollment.update!(status: 'approved') }

      it 'returns error' do
        delete :cancel, params: { id: enrollment.id }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Można anulować tylko oczekujące wnioski')
      end
    end

    context 'with non-existent enrollment' do
      it 'returns not found' do
        delete :cancel, params: { id: 'non-existent-id' }, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #pending' do
    it 'returns pending enrollments' do
      enrollment = create(:student_class_enrollment, student: student, school_class: school_class, status: 'pending')

      get :pending, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['enrollments'].length).to eq(1)
      expect(json['enrollments'][0]['id']).to eq(enrollment.id)
      expect(json['enrollments'][0]['status']).to eq('pending')
    end

    it 'does not return approved enrollments' do
      create(:student_class_enrollment, student: student, school_class: school_class, status: 'approved')

      get :pending, format: :json

      json = JSON.parse(response.body)
      expect(json['enrollments']).to be_empty
    end
  end
end
