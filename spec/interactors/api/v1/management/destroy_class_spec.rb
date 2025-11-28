# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::DestroyClass do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: '2025/2026',
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
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
          params: { id: school_class.id }
        }
      end

      it 'destroys the class' do
        class_id = school_class.id
        result = described_class.call(context)

        expect(result).to be_success
        expect(SchoolClass.find_by(id: class_id)).to be_nil
        expect(result.status).to eq(:no_content)
      end

      it 'fails when class does not exist' do
        context[:params][:id] = SecureRandom.uuid
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Klasa nie została znaleziona')
        expect(result.status).to eq(:not_found)
      end

      it 'fails when class belongs to another school' do
        other_school = create(:school)
        other_class = SchoolClass.create!(
          school: other_school,
          name: '5A',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        context[:params][:id] = other_class.id
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Klasa nie została znaleziona')
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: { id: school_class.id }
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
        # Create a user role for another school, then remove all roles to simulate no school access
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
          params: { id: school_class.id }
        }
      end

      it 'fails with school error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end
  end
end
