# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'LearningModules interactors' do
  let(:user) { create(:user) }
  let(:learning_module) { create(:learning_module, published: true) }

  describe Api::V1::LearningModules::ListLearningModules do
    it 'returns published learning modules for authenticated users' do
      create_list(:learning_module, 2, published: true)

      result = described_class.call(current_user: user, params: {})

      expect(result).to be_success
      expect(result.form).to all(be_published)
      expect(result.serializer).to eq(LearningModuleSerializer)
    end

    it 'fails for anonymous users' do
      result = described_class.call(current_user: nil, params: {})

      expect(result).to be_failure
      expect(result.message).to include('Brak uprawnień')
    end
  end

  describe Api::V1::LearningModules::ShowLearningModule do
    it 'returns the module when it is published' do
      result = described_class.call(current_user: user, params: { id: learning_module.id })

      expect(result).to be_success
      expect(result.form).to eq(learning_module)
    end

    it 'allows admin users to view unpublished modules' do
      learning_module.update!(published: false)
      admin_role = Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' }
      UserRole.create!(user: user, role: admin_role, school: user.school)

      result = described_class.call(current_user: user, params: { id: learning_module.id })

      expect(result).to be_success
    end

    it 'denies access to unpublished modules for non-admins' do
      learning_module.update!(published: false)

      result = described_class.call(current_user: user, params: { id: learning_module.id })

      expect(result).to be_failure
      expect(result.status).to eq(:forbidden)
    end

    it 'fails when module does not exist' do
      result = described_class.call(current_user: user, params: { id: SecureRandom.uuid })

      expect(result).to be_failure
      expect(result.status).to eq(:not_found)
    end
  end
end
