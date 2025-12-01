# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::LockAdministration do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:administration) do
    user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
    UserRole.create!(user: user, role: principal_role, school: school)
    user
  end

  before do
    principal_role
    school_manager_role
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: { id: administration.id }
        }
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'locks the administration account' do
        result = described_class.call(context)

        expect(result).to be_success
        administration.reload
        expect(administration.locked_at).to be_present
        expect(result.status).to eq(:ok)
        expect(result.serializer).to eq(AdministrationSerializer)
        expect(result.school_id).to eq(school.id)
      end

      it 'unlocks the administration account if already locked' do
        administration.update!(locked_at: Time.current)
        result = described_class.call(context)

        expect(result).to be_success
        administration.reload
        expect(administration.locked_at).to be_nil
      end

      it 'resets failed_attempts when locking' do
        administration.update!(failed_attempts: 5)
        result = described_class.call(context)

        expect(result).to be_success
        administration.reload
        expect(administration.failed_attempts).to eq(0)
      end

      it 'resets failed_attempts and unlock_token when unlocking' do
        administration.update!(locked_at: Time.current, failed_attempts: 5, unlock_token: 'token123')
        result = described_class.call(context)

        expect(result).to be_success
        administration.reload
        expect(administration.failed_attempts).to eq(0)
        expect(administration.unlock_token).to be_nil
      end

      it 'fails when administration does not exist' do
        context[:params][:id] = SecureRandom.uuid
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Użytkownik administracji nie został znaleziony')
        expect(result.status).to eq(:not_found)
      end

      it 'fails when administration belongs to another school' do
        other_school = create(:school)
        other_admin = create(:user, school: other_school)
        UserRole.create!(user: other_admin, role: principal_role, school: other_school)

        context[:params][:id] = other_admin.id
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Użytkownik administracji nie został znaleziony')
      end

      it 'prevents self lock' do
        context[:params][:id] = school_manager.id
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
        expect(result.message.first).to include('własnego konta')
        expect(result.status).to eq(:unprocessable_entity)
        school_manager.reload
        expect(school_manager.locked_at).to be_nil
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: { id: administration.id }
        }
      end

      it 'fails with authorization error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end

    context 'when user has no school' do
      let(:user_without_school) do
        user = build(:user, school: nil)
        user.save(validate: false)
        user.update_column(:school_id, nil) if user.school_id.present?
        other_school = create(:school)
        UserRole.create!(user: user, role: school_manager_role, school: other_school)
        user.user_roles.destroy_all
        user.update_column(:school_id, nil)
        user.reload
        user
      end
      let(:context) do
        {
          current_user: user_without_school,
          params: { id: administration.id }
        }
      end

      it 'fails with authorization error (no school means no access)' do
        result = described_class.call(context)

        expect(result).to be_failure
        # User without school doesn't pass authorization check
        expect(result.message).to include('Brak uprawnień')
      end
    end
  end
end
