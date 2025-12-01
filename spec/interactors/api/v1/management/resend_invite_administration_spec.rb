# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ResendInviteAdministration do
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
    user.update_column(:confirmed_at, nil) # Set confirmed_at to nil without callbacks
    UserRole.create!(user: user, role: principal_role, school: school)
    user.reload
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

      it 'sends confirmation instructions' do
        # Clear any existing confirmation token
        administration.update_column(:confirmation_token, nil)
        administration.update_column(:confirmation_sent_at, nil)

        # Call the interactor
        result = described_class.call(context)

        expect(result).to be_success
        # Verify that confirmation token was generated (side effect of send_confirmation_instructions)
        administration.reload
        expect(administration.confirmation_token).to be_present
        expect(administration.confirmation_sent_at).to be_present
      end

      it 'sets status and form message' do
        result = described_class.call(context)
        expect(result.status).to eq(:ok)
        expect(result.form).to be_a(Hash)
        expect(result.form[:message]).to include('wysłane ponownie')
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
