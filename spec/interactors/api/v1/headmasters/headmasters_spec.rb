# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Headmasters interactors' do
  def ac_params(hash)
    ActionController::Parameters.new(hash)
  end

  before do
    admin_role
    principal_role
  end

  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school) { create(:school) }
  let(:admin_user) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: admin_role, school: school)
    user
  end
  let(:headmaster) do
    user = create(:user, school: school, confirmed_at: nil)
    UserRole.create!(user: user, role: principal_role, school: school)
    user
  end

  describe Api::V1::Headmasters::CreateHeadmaster do
    it 'creates a headmaster and assigns principal role' do
      params = {
        current_user: admin_user,
        params: ac_params(
          headmaster: {
            first_name: 'Jan',
            last_name: 'Kowalski',
            email: 'jan.headmaster@example.com',
            password: 'Password1!',
            password_confirmation: 'Password1!',
            school_id: school.id,
            metadata: { phone: '+48 123 456 789' }
          }
        )
      }

      result = described_class.call(params)
      created = result.form.reload

      expect(result).to be_success
      expect(created.first_name).to eq('Jan')
      expect(created.school).to eq(school)
      expect(created.roles.pluck(:key)).to include('principal')
      expect(result.serializer).to eq(HeadmasterSerializer)
    end
  end

  describe Api::V1::Headmasters::ListHeadmasters do
    it 'returns all principals for admin users' do
      headmaster
      result = described_class.call(current_user: admin_user, params: {})

      expect(result).to be_success
      expect(result.form.map(&:id)).to include(headmaster.id)
      expect(result.serializer).to eq(HeadmasterSerializer)
    end
  end

  describe Api::V1::Headmasters::ShowHeadmaster do
    it 'returns specific principal' do
      result = described_class.call(current_user: admin_user, params: { id: headmaster.id })

      expect(result).to be_success
      expect(result.form).to eq(headmaster)
    end

    it 'fails when principal is missing' do
      result = described_class.call(current_user: admin_user, params: { id: SecureRandom.uuid })

      expect(result).to be_failure
      expect(result.status).to eq(:not_found)
    end
  end

  describe Api::V1::Headmasters::UpdateHeadmaster do
    it 'updates metadata by merging values' do
      headmaster.update!(metadata: { phone: '+48 000 000 000', address: 'Old' })

      params = {
        current_user: admin_user,
        params: ac_params(
          id: headmaster.id,
          headmaster: {
            first_name: 'Anna',
            metadata: {
              phone: '+48 999 999 999'
            }
          }
        )
      }

      result = described_class.call(params)

      expect(result).to be_success
      expect(result.form.first_name).to eq('Anna')
      metadata = result.form.reload.metadata
      expect(metadata['phone']).to eq('+48 999 999 999')
      expect(metadata['address']).to eq('Old')
    end
  end

  describe Api::V1::Headmasters::DestroyHeadmaster do
    it 'removes the principal' do
      target = headmaster

      result = described_class.call(current_user: admin_user, params: { id: target.id })

      expect(result).to be_success
      expect(User.exists?(target.id)).to be(false)
    end
  end

  describe Api::V1::Headmasters::LockHeadmaster do
    it 'locks and unlocks a headmaster account' do
      result = described_class.call(current_user: admin_user, params: { id: headmaster.id })

      expect(result).to be_success
      expect(result.form[:message]).to include('zablokowane')
      expect(headmaster.reload.locked_at).to be_present

      unlock_result = described_class.call(current_user: admin_user, params: { id: headmaster.id })
      expect(unlock_result.form[:message]).to include('odblokowane')
      expect(headmaster.reload.locked_at).to be_nil
    end
  end

  describe Api::V1::Headmasters::ResendInviteHeadmaster do
    it 'sends confirmation instructions again' do
      headmaster.update!(confirmation_token: nil, confirmation_sent_at: nil)

      result = described_class.call(current_user: admin_user, params: { id: headmaster.id })

      expect(result).to be_success
      expect(headmaster.reload.confirmation_token).to be_present
      expect(result.form[:message]).to include('Zaproszenie zostało wysłane ponownie')
    end
  end
end
