# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Students interactors' do
  def ac_params(hash)
    ActionController::Parameters.new(hash)
  end

  before do
    admin_role
    student_role
  end

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:school) { create(:school) }
  let(:admin_user) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: admin_role, school: school)
    user
  end
  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end

  describe Api::V1::Students::CreateStudent do
    it 'creates a student with generated password if missing' do
      params = {
        current_user: admin_user,
        params: ac_params(
          student: {
            first_name: 'Ola',
            last_name: 'Nowak',
            email: 'ola.student@example.com',
            school_id: school.id,
            metadata: { birth_date: '2010-01-01' }
          }
        )
      }

      result = described_class.call(params)
      created = result.form.reload

      expect(result).to be_success
      expect(created.school).to eq(school)
      expect(created.roles.pluck(:key)).to include('student')
      expect(created.birthdate).to eq(Date.parse('2010-01-01'))
    end
  end

  describe Api::V1::Students::ListStudents do
    it 'returns paginated students and supports search' do
      student
      params = {
        current_user: admin_user,
        params: { search: student.first_name, page: 1, per_page: 5 }
      }
      result = described_class.call(params)

      expect(result).to be_success
      expect(result.form.map(&:id)).to include(student.id)
      expect(result.pagination[:per_page]).to eq(5)
    end
  end

  describe Api::V1::Students::ShowStudent do
    it 'returns the student' do
      result = described_class.call(current_user: admin_user, params: { id: student.id })

      expect(result).to be_success
      expect(result.form).to eq(student)
    end
  end

  describe Api::V1::Students::UpdateStudent do
    it 'merges metadata and updates birthdate' do
      student.update!(metadata: { phone: '+48 000 000 000' })

      params = {
        current_user: admin_user,
        params: ac_params(
          id: student.id,
          student: {
            first_name: 'Updated',
            metadata: { birth_date: '2005-05-05' }
          }
        )
      }

      result = described_class.call(params)

      expect(result).to be_success
      expect(result.form.first_name).to eq('Updated')
      expect(result.form.birthdate).to eq(Date.parse('2005-05-05'))
      metadata = result.form.reload.metadata
      expect(metadata['phone']).to eq('+48 000 000 000')
    end
  end

  describe Api::V1::Students::LockStudent do
    it 'locks and unlocks the account' do
      lock_result = described_class.call(current_user: admin_user, params: { id: student.id })

      expect(lock_result).to be_success
      expect(student.reload.locked_at).to be_present

      unlock_result = described_class.call(current_user: admin_user, params: { id: student.id })
      expect(unlock_result).to be_success
      expect(student.reload.locked_at).to be_nil
    end
  end

  describe Api::V1::Students::ResendInviteStudent do
    it 'sends confirmation instructions again' do
      student.update!(confirmation_token: nil, confirmation_sent_at: nil)

      result = described_class.call(current_user: admin_user, params: { id: student.id })

      expect(result).to be_success
      expect(student.reload.confirmation_token).to be_present
    end
  end

  describe Api::V1::Students::DestroyStudent do
    it 'deletes the student' do
      target = student

      result = described_class.call(current_user: admin_user, params: { id: target.id })

      expect(result).to be_success
      expect(User.exists?(target.id)).to be(false)
    end
  end
end
