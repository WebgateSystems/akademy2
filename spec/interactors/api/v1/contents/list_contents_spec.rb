# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Contents::ListContents do
  let(:user) { create(:user) }
  let(:learning_module) { create(:learning_module, published: true) }
  let!(:content) { create(:content, learning_module: learning_module) }

  context 'when user is authenticated' do
    let(:context) { { current_user: user, params: {} } }

    it 'returns published contents' do
      result = described_class.call(context)

      expect(result).to be_success
      expect(result.form).to include(content)
      expect(result.serializer).to eq(ContentSerializer)
    end

    it 'filters by learning module id' do
      other_module = create(:learning_module, published: true)
      create(:content, learning_module: other_module)

      result = described_class.call(context.merge(params: { learning_module_id: learning_module.id }))

      expect(result.form).to contain_exactly(content)
    end
  end

  context 'when module is unpublished' do
    let(:learning_module) { create(:learning_module, published: false) }
    let(:context) { { current_user: user, params: {} } }

    it 'hides content from non-admin users' do
      result = described_class.call(context)

      expect(result.form).to be_empty
    end

    it 'allows admin users to see unpublished content' do
      admin_role = Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' }
      UserRole.create!(user: user, role: admin_role, school: user.school)

      result = described_class.call(context)

      expect(result.form).to include(content)
    end
  end

  context 'when user is missing' do
    it 'fails authorization' do
      result = described_class.call(current_user: nil, params: {})

      expect(result).to be_failure
      expect(result.message).to include('Brak uprawnień')
    end
  end
end
