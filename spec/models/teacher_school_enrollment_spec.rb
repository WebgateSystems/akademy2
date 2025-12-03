# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeacherSchoolEnrollment, type: :model do
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:school) { create(:school) }
  let(:teacher) do
    user = create(:user, school: nil)
    UserRole.create!(user: user, role: teacher_role, school: nil)
    user
  end

  before { teacher_role }

  describe 'associations' do
    it 'belongs to school' do
      enrollment = described_class.new(teacher: teacher, school: school)
      expect(enrollment.school).to eq(school)
    end

    it 'belongs to teacher (user)' do
      enrollment = described_class.new(teacher: teacher, school: school)
      expect(enrollment.teacher).to eq(teacher)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      enrollment = described_class.new(
        teacher: teacher,
        school: school,
        status: 'pending'
      )
      expect(enrollment).to be_valid
    end

    it 'requires a teacher' do
      enrollment = described_class.new(school: school, status: 'pending')
      expect(enrollment).not_to be_valid
    end

    it 'requires a school' do
      enrollment = described_class.new(teacher: teacher, status: 'pending')
      expect(enrollment).not_to be_valid
    end
  end

  describe 'status' do
    it 'defaults to pending' do
      enrollment = described_class.create!(teacher: teacher, school: school)
      expect(enrollment.status).to eq('pending')
    end

    it 'can be set to approved' do
      enrollment = described_class.create!(
        teacher: teacher,
        school: school,
        status: 'approved',
        joined_at: Time.current
      )
      expect(enrollment.status).to eq('approved')
    end
  end

  describe 'uniqueness' do
    it 'prevents duplicate enrollments for same teacher and school' do
      described_class.create!(teacher: teacher, school: school, status: 'pending')

      duplicate = described_class.new(teacher: teacher, school: school, status: 'pending')
      expect(duplicate).not_to be_valid
    end

    it 'allows same teacher in different schools' do
      other_school = create(:school)
      described_class.create!(teacher: teacher, school: school, status: 'pending')

      other_enrollment = described_class.new(teacher: teacher, school: other_school, status: 'pending')
      expect(other_enrollment).to be_valid
    end
  end

  describe '#approve!' do
    let(:enrollment) { described_class.create!(teacher: teacher, school: school, status: 'pending') }

    it 'updates status to approved' do
      enrollment.update!(status: 'approved', joined_at: Time.current)
      expect(enrollment.reload.status).to eq('approved')
    end

    it 'sets joined_at timestamp' do
      enrollment.update!(status: 'approved', joined_at: Time.current)
      expect(enrollment.reload.joined_at).to be_present
    end
  end

  describe 'factory' do
    it 'creates pending enrollment' do
      enrollment = create(:teacher_school_enrollment, :pending)
      expect(enrollment.status).to eq('pending')
    end

    it 'creates approved enrollment' do
      enrollment = create(:teacher_school_enrollment, :approved)
      expect(enrollment.status).to eq('approved')
      expect(enrollment.joined_at).to be_present
    end
  end
end
