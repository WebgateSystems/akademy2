# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ApproveStudent do
  let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }

  let(:school) { create(:school) }
  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: '2025/2026',
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
  end
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:student) do
    user = create(:user, school: school, confirmed_at: nil)
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class)
    user
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) { { current_user: school_manager, params: { id: student.id } } }

      before do
        principal_role
        school_manager_role
        school_manager
        school_class
        NotificationService.create_student_awaiting_approval(student: student, school: school)
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'confirms student' do
        described_class.call(context)
        student.reload
        expect(student.confirmed_at).to be_present
      end

      it 'resolves notification' do
        described_class.call(context)
        notification = Notification.find_by(
          notification_type: 'student_awaiting_approval',
          school: school,
          target_role: 'school_manager'
        )
        expect(notification&.resolved_at).to be_present
      end

      it 'logs approval event' do
        expect do
          described_class.call(context)
        end.to change(Event, :count).by(1)

        event = Event.where(event_type: 'student_approved', user: school_manager).last
        expect(event).to be_present
        expect(event.data['student_id']).to eq(student.id)
      end

      it 'sets serializer' do
        result = described_class.call(context)
        expect(result.serializer).to eq(StudentSerializer)
      end
    end

    context 'when student already confirmed' do
      let(:confirmed_student) do
        user = create(:user, school: school, confirmed_at: Time.current)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class)
        user
      end
      let(:context) { { current_user: school_manager, params: { id: confirmed_student.id } } }

      before do
        school_manager
        school_class
        confirmed_student
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
      end

      it 'sets error message' do
        result = described_class.call(context)
        expect(result.message).to be_present
        expect(result.message.first).to include('już zatwierdzony')
      end
    end

    context 'when user is not authorized' do
      let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
      let(:admin_user) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: admin_role, school: school)
        user
      end
      let(:context) { { current_user: admin_user, params: { id: student.id } } }

      before do
        school_class
        student
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
      end
    end
  end
end
