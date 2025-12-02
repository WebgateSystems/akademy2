# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Schools interactors' do
  def ac_params(hash)
    ActionController::Parameters.new(hash)
  end

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.create!(user: user, role: admin_role, school: user.school)
    user
  end
  let(:school) { create(:school) }

  describe Api::V1::Schools::CreateSchool do
    it 'creates a school and derives slug' do
      params = {
        current_user: admin_user,
        params: ac_params(
          school: {
            name: 'Test Academy',
            city: 'Warszawa',
            country: 'PL'
          }
        )
      }

      result = described_class.call(params)

      expect(result).to be_success
      expect(result.form.slug).to eq('test-academy')
      expect(result.serializer).to eq(SchoolSerializer)
    end
  end

  describe Api::V1::Schools::ListSchools do
    it 'returns schools for admin users' do
      school
      result = described_class.call(current_user: admin_user, params: {})

      expect(result).to be_success
      expect(result.form).to include(school)
    end
  end

  describe Api::V1::Schools::ShowSchool do
    it 'returns requested school' do
      result = described_class.call(current_user: admin_user, params: { id: school.id })

      expect(result).to be_success
      expect(result.form).to eq(school)
    end
  end

  describe Api::V1::Schools::UpdateSchool do
    it 'updates school attributes' do
      result = described_class.call(
        current_user: admin_user,
        params: ac_params(id: school.id, school: { name: 'Updated School' })
      )

      expect(result).to be_success
      expect(result.form.name).to eq('Updated School')
    end
  end

  describe Api::V1::Schools::DestroySchool do
    it 'removes the school' do
      school_to_remove = create(:school)

      result = described_class.call(current_user: admin_user, params: { id: school_to_remove.id })

      expect(result).to be_success
      expect(result.status).to eq(:no_content)
      expect(School.exists?(school_to_remove.id)).to be(false)
    end
  end
end
