# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::LockParent do
  let(:parent_role) { Role.find_or_create_by!(key: 'parent') { |r| r.name = 'Parent' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:academic_year) { school.academic_years.create!(year: '2024/2025', is_current: true, started_at: Date.current) }

  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end

  let(:parent_user) do
    user = create(:user, first_name: 'Jan', last_name: 'Kowalski', school: school)
    UserRole.create!(user: user, role: parent_role, school: school)
    user
  end

  before do
    parent_role
    school_manager_role
    academic_year
    school_manager.reload
  end

  describe '#call' do
    context 'when user is authorized' do
      context 'when locking unlocked parent' do
        let(:context) do
          {
            current_user: school_manager,
            params: { id: parent_user.id }
          }
        end

        it 'succeeds' do
          result = described_class.call(context)
          expect(result).to be_success
        end

        it 'locks the parent' do
          described_class.call(context)
          parent_user.reload
          expect(parent_user.locked_at).to be_present
        end

        it 'sets serializer and status' do
          result = described_class.call(context)
          expect(result.serializer).to eq(ParentSerializer)
          expect(result.status).to eq(:ok)
        end
      end

      context 'when unlocking locked parent' do
        let(:locked_parent) do
          user = create(:user, school: school, locked_at: Time.current)
          UserRole.create!(user: user, role: parent_role, school: school)
          user
        end

        let(:context) do
          {
            current_user: school_manager,
            params: { id: locked_parent.id }
          }
        end

        it 'succeeds' do
          result = described_class.call(context)
          expect(result).to be_success
        end

        it 'unlocks the parent' do
          described_class.call(context)
          locked_parent.reload
          expect(locked_parent.locked_at).to be_nil
        end
      end
    end

    context 'when parent not found' do
      let(:context) do
        {
          current_user: school_manager,
          params: { id: SecureRandom.uuid }
        }
      end

      it 'fails with not found error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.status).to eq(:not_found)
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: { id: parent_user.id }
        }
      end

      it 'fails with authorization error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end
  end
end
