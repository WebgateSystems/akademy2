# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Teachers interactors' do
  def ac_params(hash)
    ActionController::Parameters.new(hash)
  end

  before do
    admin_role
    teacher_role
  end

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:school) { create(:school) }
  let(:admin_user) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: admin_role, school: school)
    user
  end
  let(:teacher) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end

  describe Api::V1::Teachers::CreateTeacher do
    it 'creates a teacher with role assigned' do
      params = {
        current_user: admin_user,
        params: ac_params(
          teacher: {
            first_name: 'Adam',
            last_name: 'Nowak',
            email: 'adam.teacher@example.com',
            school_id: school.id,
            metadata: { phone: '+48 555 555 555' }
          }
        )
      }

      result = described_class.call(params)
      created = result.form.reload

      expect(result).to be_success
      expect(created.school).to eq(school)
      expect(created.roles.pluck(:key)).to include('teacher')
    end
  end

  describe Api::V1::Teachers::ListTeachers do
    it 'returns teachers and supports search' do
      teacher
      params = {
        current_user: admin_user,
        params: { search: teacher.first_name }
      }

      result = described_class.call(params)

      expect(result).to be_success
      expect(result.form.map(&:id)).to include(teacher.id)
    end
  end

  describe Api::V1::Teachers::ShowTeacher do
    it 'returns teacher details' do
      result = described_class.call(current_user: admin_user, params: { id: teacher.id })

      expect(result).to be_success
      expect(result.form).to eq(teacher)
    end
  end

  describe Api::V1::Teachers::UpdateTeacher do
    it 'updates teacher data and merges metadata' do
      teacher.update!(metadata: { phone: '+48 111 111 111' })
      params = {
        current_user: admin_user,
        params: ac_params(
          id: teacher.id,
          teacher: {
            first_name: 'Updated',
            metadata: { phone: '+48 222 222 222' }
          }
        )
      }

      result = described_class.call(params)

      expect(result).to be_success
      expect(result.form.first_name).to eq('Updated')
      metadata = result.form.reload.metadata
      expect(metadata['phone']).to eq('+48 222 222 222')
    end
  end

  describe Api::V1::Teachers::LockTeacher do
    it 'toggles locked state' do
      lock_result = described_class.call(current_user: admin_user, params: { id: teacher.id })
      expect(lock_result).to be_success
      expect(teacher.reload.locked_at).to be_present

      unlock_result = described_class.call(current_user: admin_user, params: { id: teacher.id })
      expect(unlock_result).to be_success
      expect(teacher.reload.locked_at).to be_nil
    end
  end

  describe Api::V1::Teachers::ResendInviteTeacher do
    it 'sends confirmation instructions' do
      teacher.update!(confirmation_token: nil, confirmation_sent_at: nil)

      result = described_class.call(current_user: admin_user, params: { id: teacher.id })

      expect(result).to be_success
      expect(teacher.reload.confirmation_token).to be_present
    end
  end

  describe Api::V1::Teachers::DestroyTeacher do
    it 'removes the teacher' do
      target = teacher

      result = described_class.call(current_user: admin_user, params: { id: target.id })

      expect(result).to be_success
      expect(User.exists?(target.id)).to be(false)
    end
  end
end
