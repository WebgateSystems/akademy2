# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ListClasses do
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
    AcademicYear.create!(school: school, year: '2025/2026', is_current: true)
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: {}
        }
      end

      it 'returns classes for current academic year' do
        class1 = SchoolClass.create!(
          school: school,
          name: '4A',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        class2 = SchoolClass.create!(
          school: school,
          name: '4B',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        SchoolClass.create!(
          school: school,
          name: '3A',
          year: '2024/2025',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to contain_exactly(class1, class2)
        expect(result.status).to eq(:ok)
        expect(result.serializer).to eq(SchoolClassSerializer)
      end

      it 'returns classes for specified year' do
        SchoolClass.create!(
          school: school,
          name: '4A',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        class_2024 = SchoolClass.create!(
          school: school,
          name: '3A',
          year: '2024/2025',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        AcademicYear.create!(school: school, year: '2024/2025', is_current: false)

        context[:params] = { year: '2024/2025' }
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to contain_exactly(class_2024)
      end

      it 'returns empty array when no classes exist' do
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to be_empty
      end

      it 'does not return classes from other schools' do
        other_school = create(:school)
        SchoolClass.create!(
          school: school,
          name: '4A',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        SchoolClass.create!(
          school: other_school,
          name: '5A',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form.count).to eq(1)
        expect(result.form.first.school).to eq(school)
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {}
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
          params: {}
        }
      end

      before do
        UserRole.create!(user: user_without_school, role: principal_role, school: create(:school))
        user_without_school.user_roles.destroy_all
      end

      it 'fails with school error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end
  end
end
