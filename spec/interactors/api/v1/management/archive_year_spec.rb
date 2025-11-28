# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ArchiveYear do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
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
          params: { year: '2024/2025' }
        }
      end

      it 'archives classes for the specified year' do
        class1 = SchoolClass.create!(
          school: school,
          name: '3A',
          year: '2024/2025',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        class2 = SchoolClass.create!(
          school: school,
          name: '3B',
          year: '2024/2025',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form[:message]).to include('2024/2025')
        expect(result.status).to eq(:ok)
        expect(class1.reload.metadata['archived']).to be true
        expect(class2.reload.metadata['archived']).to be true
        expect(class1.reload.metadata['archived_at']).to be_present
        expect(class2.reload.metadata['archived_at']).to be_present
      end

      it 'uses default year when year is not provided' do
        class1 = SchoolClass.create!(
          school: school,
          name: '4A',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        context[:params] = {}
        result = described_class.call(context)

        expect(result).to be_success
        expect(class1.reload.metadata['archived']).to be true
      end

      it 'fails when no classes exist for the year' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak klas do zarchiwizowania')
      end

      it 'only archives classes for the specified year' do
        class_2024 = SchoolClass.create!(
          school: school,
          name: '3A',
          year: '2024/2025',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        class_2025 = SchoolClass.create!(
          school: school,
          name: '4A',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )

        result = described_class.call(context)

        expect(result).to be_success
        expect(class_2024.reload.metadata['archived']).to be true
        expect(class_2025.reload.metadata['archived']).to be_nil
      end

      it 'only archives classes for the specified school' do
        other_school = create(:school)
        class_school = SchoolClass.create!(
          school: school,
          name: '3A',
          year: '2024/2025',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        class_other = SchoolClass.create!(
          school: other_school,
          name: '5A',
          year: '2024/2025',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )

        result = described_class.call(context)

        expect(result).to be_success
        expect(class_school.reload.metadata['archived']).to be true
        expect(class_other.reload.metadata['archived']).to be_nil
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: { year: '2024/2025' }
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
          params: { year: '2024/2025' }
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
