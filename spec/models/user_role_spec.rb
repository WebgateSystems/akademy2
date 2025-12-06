# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserRole, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:role) }
    it { is_expected.to belong_to(:school).optional }
  end

  describe 'validations' do
    let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
    let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
    let(:school) { create(:school) }
    let(:user) { create(:user, school: school) }

    context 'when adding student role' do
      it 'allows student role if user has no other roles' do
        user_role = described_class.new(user: user, role: student_role, school: school)
        expect(user_role).to be_valid
      end

      it 'prevents student role if user already has other roles' do
        described_class.create!(user: user, role: teacher_role, school: school)
        user_role = described_class.new(user: user, role: student_role, school: school)
        expect(user_role).not_to be_valid
        expect(user_role.errors[:role]).to include('student nie może posiadać innych ról')
      end
    end

    context 'when adding non-student role' do
      it 'allows non-student role if user is not a student' do
        user_role = described_class.new(user: user, role: teacher_role, school: school)
        expect(user_role).to be_valid
      end

      it 'prevents non-student role if user is already a student' do
        described_class.create!(user: user, role: student_role, school: school)
        user_role = described_class.new(user: user, role: teacher_role, school: school)
        expect(user_role).not_to be_valid
        expect(user_role.errors[:role]).to include('nie można dodać innych ról do studenta')
      end
    end
  end
end
