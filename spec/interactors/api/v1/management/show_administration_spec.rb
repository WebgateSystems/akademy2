# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ShowAdministration do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:administration) do
    user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
    UserRole.create!(user: user, role: principal_role, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    user
  end

  before do
    principal_role
    school_manager_role
    teacher_role
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

      it 'returns the administration' do
        result = described_class.call(context)
        expect(result.form).to eq(administration)
        expect(result.status).to eq(:ok)
        expect(result.serializer).to eq(AdministrationSerializer)
        expect(result.school_id).to eq(school.id)
      end

      it 'finds administration with principal and teacher roles' do
        admin_with_roles = create(:user, school: school)
        UserRole.create!(user: admin_with_roles, role: principal_role, school: school)
        UserRole.create!(user: admin_with_roles, role: teacher_role, school: school)

        context[:params][:id] = admin_with_roles.id
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to eq(admin_with_roles)
      end

      it 'finds administration with school_manager and teacher roles' do
        admin_with_roles = create(:user, school: school)
        UserRole.create!(user: admin_with_roles, role: school_manager_role, school: school)
        UserRole.create!(user: admin_with_roles, role: teacher_role, school: school)

        context[:params][:id] = admin_with_roles.id
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to eq(admin_with_roles)
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
        expect(result.status).to eq(:not_found)
      end

      it 'fails when user has only teacher role (no admin role)' do
        teacher_only = create(:user, school: school)
        UserRole.create!(user: teacher_only, role: teacher_role, school: school)

        context[:params][:id] = teacher_only.id
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Użytkownik administracji nie został znaleziony')
        expect(result.status).to eq(:not_found)
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
