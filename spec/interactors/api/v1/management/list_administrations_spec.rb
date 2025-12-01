# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ListAdministrations do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
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
          params: {}
        }
      end

      it 'returns administrations for the school' do
        admin1 = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
        UserRole.create!(user: admin1, role: principal_role, school: school)
        admin2 = create(:user, school: school, first_name: 'Anna', last_name: 'Nowak')
        UserRole.create!(user: admin2, role: school_manager_role, school: school)
        UserRole.create!(user: admin2, role: teacher_role, school: school)

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to include(admin1, admin2)
        expect(result.status).to eq(:ok)
        expect(result.serializer).to eq(AdministrationSerializer)
        expect(result.school_id).to eq(school.id)
      end

      it 'includes current user if they are an administrator' do
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to include(school_manager)
      end

      it 'does not return administrations from other schools' do
        other_school = create(:school)
        admin_school = create(:user, school: school)
        UserRole.create!(user: admin_school, role: principal_role, school: school)
        admin_other = create(:user, school: other_school)
        UserRole.create!(user: admin_other, role: principal_role, school: other_school)

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to include(admin_school)
        expect(result.form).not_to include(admin_other)
      end

      it 'supports pagination' do
        25.times do |i|
          admin = create(:user, school: school, first_name: "Admin#{i}")
          UserRole.create!(user: admin, role: principal_role, school: school)
        end

        context[:params] = { page: 1, per_page: 10 }
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form.count).to eq(10)
        expect(result.pagination[:page]).to eq(1)
        expect(result.pagination[:per_page]).to eq(10)
        expect(result.pagination[:total]).to be >= 25
      end

      it 'supports search by name' do
        admin1 = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
        UserRole.create!(user: admin1, role: principal_role, school: school)
        admin2 = create(:user, school: school, first_name: 'Anna', last_name: 'Nowak')
        UserRole.create!(user: admin2, role: school_manager_role, school: school)

        context[:params] = { search: 'Jan' }
        result = described_class.call(context)

        expect(result).to be_success
        found = result.form.find { |a| a.id == admin1.id }
        expect(found).to be_present
      end

      it 'supports search by email' do
        admin1 = create(:user, school: school, email: 'jan@example.com')
        UserRole.create!(user: admin1, role: principal_role, school: school)
        admin2 = create(:user, school: school, email: 'anna@example.com')
        UserRole.create!(user: admin2, role: school_manager_role, school: school)

        context[:params] = { q: 'jan@example.com' }
        result = described_class.call(context)

        expect(result).to be_success
        found = result.form.find { |a| a.id == admin1.id }
        expect(found).to be_present
      end

      it 'includes users with teacher role if they also have admin role' do
        admin_with_teacher = create(:user, school: school)
        UserRole.create!(user: admin_with_teacher, role: principal_role, school: school)
        UserRole.create!(user: admin_with_teacher, role: teacher_role, school: school)

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to include(admin_with_teacher)
      end

      it 'does not include users with only teacher role' do
        teacher_only = create(:user, school: school)
        UserRole.create!(user: teacher_only, role: teacher_role, school: school)

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).not_to include(teacher_only)
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

      it 'fails with authorization error (no school means no access)' do
        result = described_class.call(context)

        expect(result).to be_failure
        # User without school doesn't pass authorization check
        expect(result.message).to include('Brak uprawnień')
      end
    end
  end
end
