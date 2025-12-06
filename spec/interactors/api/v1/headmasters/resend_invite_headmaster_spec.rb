# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Headmasters::ResendInviteHeadmaster do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }

  let(:admin_user) do
    user = create(:user)
    UserRole.create!(user: user, role: admin_role)
    user
  end

  let(:regular_user) { create(:user) }

  let(:headmaster) do
    user = create(:user)
    UserRole.create!(user: user, role: principal_role)
    user
  end

  describe '#call' do
    context 'when user is authorized admin' do
      context 'and headmaster exists' do
        let(:context) do
          {
            current_user: admin_user,
            params: { id: headmaster.id }
          }
        end

        it 'succeeds' do
          result = described_class.call(context)
          expect(result).to be_success
        end

        it 'returns success message' do
          result = described_class.call(context)
          expect(result.form[:message]).to eq('Zaproszenie zostało wysłane ponownie')
        end

        it 'returns ok status' do
          result = described_class.call(context)
          expect(result.status).to eq(:ok)
        end

        it 'sends confirmation instructions' do
          expect_any_instance_of(User).to receive(:send_confirmation_instructions)
          described_class.call(context)
        end
      end

      context 'and headmaster does not exist' do
        let(:context) do
          {
            current_user: admin_user,
            params: { id: SecureRandom.uuid }
          }
        end

        it 'fails' do
          result = described_class.call(context)
          expect(result).to be_failure
        end

        it 'returns not found status' do
          result = described_class.call(context)
          expect(result.status).to eq(:not_found)
        end

        it 'returns error message' do
          result = described_class.call(context)
          expect(result.message).to include('Dyrektor nie został znaleziony')
        end
      end
    end

    context 'when user is not authorized' do
      let(:context) do
        {
          current_user: regular_user,
          params: { id: headmaster.id }
        }
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
      end

      it 'returns authorization error' do
        result = described_class.call(context)
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when current_user is nil' do
      let(:context) do
        {
          current_user: nil,
          params: { id: headmaster.id }
        }
      end

      it 'fails' do
        result = described_class.call(context)
        expect(result).to be_failure
      end
    end
  end
end
