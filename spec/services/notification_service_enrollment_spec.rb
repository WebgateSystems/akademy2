# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationService, 'enrollment notifications' do
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, school: school) }
  let(:student) { create(:user, first_name: 'Jan', last_name: 'Kowalski') }
  let(:teacher) { create(:user) }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher', name: 'Teacher') }

  before do
    teacher.roles << teacher_role unless teacher.roles.include?(teacher_role)
    create(:teacher_class_assignment, teacher: teacher, school_class: school_class)
  end

  describe '.create_student_enrollment_request' do
    it 'creates notification for teachers assigned to the class' do
      expect do
        described_class.create_student_enrollment_request(student: student, school_class: school_class)
      end.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.notification_type).to eq('student_enrollment_request')
      expect(notification.target_role).to eq('teacher')
      expect(notification.school).to eq(school)
      expect(notification.user).to eq(student)
      expect(notification.title).to eq('Nowy wniosek o dołączenie')
      expect(notification.message).to include('Jan Kowalski')
      expect(notification.message).to include(school_class.name)
    end

    it 'does not create duplicate notifications' do
      described_class.create_student_enrollment_request(student: student, school_class: school_class)

      expect do
        described_class.create_student_enrollment_request(student: student, school_class: school_class)
      end.not_to change(Notification, :count)
    end

    it 'does not create notification if no teachers assigned' do
      TeacherClassAssignment.destroy_all

      expect do
        described_class.create_student_enrollment_request(student: student, school_class: school_class)
      end.not_to change(Notification, :count)
    end

    it 'uses phone if student has no name' do
      student.update!(first_name: nil, last_name: nil, phone: '+48123456789')

      described_class.create_student_enrollment_request(student: student, school_class: school_class)

      notification = Notification.last
      expect(notification.message).to include('+48123456789')
    end
  end

  describe '.resolve_student_enrollment_request' do
    before do
      described_class.create_student_enrollment_request(student: student, school_class: school_class)
    end

    it 'resolves the notification' do
      notification = Notification.last
      expect(notification.resolved_at).to be_nil

      described_class.resolve_student_enrollment_request(student: student, school_class: school_class)

      notification.reload
      expect(notification.resolved_at).to be_present
    end

    it 'does not fail if no notification exists' do
      Notification.destroy_all

      expect do
        described_class.resolve_student_enrollment_request(student: student, school_class: school_class)
      end.not_to raise_error
    end
  end
end
