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

    context 'when student already confirmed but enrollment is pending' do
      # With new logic, confirmed_at on user doesn't matter - enrollment status does
      let(:confirmed_student) do
        user = create(:user, school: school, confirmed_at: Time.current)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'pending')
        user
      end
      let(:context) { { current_user: school_manager, params: { id: confirmed_student.id } } }

      before do
        school_manager
        school_class
        confirmed_student
        NotificationService.create_student_awaiting_approval(student: confirmed_student, school: school)
      end

      it 'succeeds (approval is about enrollment, not email confirmation)' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'approves the enrollment' do
        described_class.call(context)
        enrollment = confirmed_student.student_class_enrollments.first
        enrollment.reload
        expect(enrollment.status).to eq('approved')
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

    context 'when teacher tries to approve student in their class' do
      let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        TeacherClassAssignment.create!(teacher: user, school_class: school_class, role: 'teacher')
        user.reload
      end
      let(:context) { { current_user: teacher, params: { id: student.id } } }

      before do
        teacher_role
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
    end

    context 'when teacher tries to approve student not in their class' do
      let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
      let(:other_class) do
        SchoolClass.create!(
          school: school,
          name: '5B',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
      end
      let(:teacher) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: teacher_role, school: school)
        TeacherClassAssignment.create!(teacher: user, school_class: other_class, role: 'teacher')
        user.reload
      end
      let(:context) { { current_user: teacher, params: { id: student.id } } }

      before do
        teacher_role
        school_class
        other_class
        student
      end

      it 'fails with authorization error' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when enrollment is already approved (no pending enrollments)' do
      let(:approved_student) do
        user = create(:user, school: school, confirmed_at: nil)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        user
      end
      let(:context) { { current_user: school_manager, params: { id: approved_student.id } } }

      before do
        school_manager
        school_class
        approved_student
      end

      it 'fails with error message about no pending enrollments' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message.first).to include('oczekujących zapisów')
      end
    end

    context 'when enrollment save fails' do
      let(:context) { { current_user: school_manager, params: { id: student.id } } }

      before do
        school_manager
        school_class
        NotificationService.create_student_awaiting_approval(student: student, school: school)
        # Mock enrollment save to return false
        allow_any_instance_of(StudentClassEnrollment).to receive(:save).and_return(false)
        allow_any_instance_of(StudentClassEnrollment).to receive(:errors).and_return(
          double(full_messages: ['Cannot save enrollment'])
        )
      end

      it 'fails with error messages' do
        result = described_class.call(context)
        expect(result).to be_failure
        expect(result.message).to include('Cannot save enrollment')
      end
    end

    context 'when user has no school' do
      let(:user_without_school) do
        user = build(:user, school: nil)
        user.save(validate: false)
        user.update_column(:school_id, nil) if user.school_id.present?
        # Don't create any roles - simulate user with no school access
        user.reload
      end
      let(:context) { { current_user: user_without_school, params: { id: student.id } } }

      before do
        school_class
        student
      end

      it 'fails with school error' do
        result = described_class.call(context)
        expect(result).to be_failure
        # When user has no school, authorize! fails first
        expect(result.message).to include('Brak uprawnień')
      end
    end
  end
end
