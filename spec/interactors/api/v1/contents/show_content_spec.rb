# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Contents::ShowContent do
  let(:user) { create(:user) }
  let(:learning_module) { create(:learning_module, published: true) }
  let(:content) { create(:content, learning_module: learning_module) }

  context 'when user is authenticated' do
    it 'returns the content when it exists' do
      result = described_class.call(current_user: user, params: { id: content.id })

      expect(result).to be_success
      expect(result.form).to eq(content)
      expect(result.serializer).to eq(ContentSerializer)
    end

    it 'fails when content does not exist' do
      result = described_class.call(current_user: user, params: { id: SecureRandom.uuid })

      expect(result).to be_failure
      expect(result.status).to eq(:not_found)
      expect(result.message).to include('Materiał nie został znaleziony')
    end

    it 'prevents access to unpublished modules for non-admins' do
      learning_module.update!(published: false)

      result = described_class.call(current_user: user, params: { id: content.id })

      expect(result).to be_failure
      expect(result.status).to eq(:forbidden)
      expect(result.message).to include('Materiał nie jest dostępny')
    end

    it 'allows admin users to access unpublished modules' do
      learning_module.update!(published: false)
      admin_role = Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' }
      UserRole.create!(user: user, role: admin_role, school: user.school)

      result = described_class.call(current_user: user, params: { id: content.id })

      expect(result).to be_success
      expect(result.form).to eq(content)
    end
  end

  context 'when no user present' do
    it 'fails authorization' do
      result = described_class.call(current_user: nil, params: { id: content.id })

      expect(result).to be_failure
      expect(result.message).to include('Brak uprawnień')
    end
  end
end
