# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::ListTeachers do
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

      it 'returns teachers for the school' do
        teacher1 = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
        UserRole.create!(user: teacher1, role: teacher_role, school: school)
        teacher2 = create(:user, school: school, first_name: 'Anna', last_name: 'Nowak')
        UserRole.create!(user: teacher2, role: teacher_role, school: school)

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to contain_exactly(teacher1, teacher2)
        expect(result.status).to eq(:ok)
        expect(result.serializer).to eq(TeacherSerializer)
      end

      it 'returns empty array when no teachers exist' do
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to be_empty
      end

      it 'does not return teachers from other schools' do
        other_school = create(:school)
        teacher_school = create(:user, school: school)
        UserRole.create!(user: teacher_school, role: teacher_role, school: school)
        teacher_other = create(:user, school: other_school)
        UserRole.create!(user: teacher_other, role: teacher_role, school: other_school)

        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form.count).to eq(1)
        expect(result.form.first).to eq(teacher_school)
      end

      it 'supports pagination' do
        25.times do |i|
          teacher = create(:user, school: school, first_name: "Teacher#{i}")
          UserRole.create!(user: teacher, role: teacher_role, school: school)
        end

        context[:params] = { page: 1, per_page: 10 }
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form.count).to eq(10)
        expect(result.pagination[:page]).to eq(1)
        expect(result.pagination[:per_page]).to eq(10)
        expect(result.pagination[:total]).to eq(25)
      end

      it 'supports search by name' do
        teacher1 = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
        UserRole.create!(user: teacher1, role: teacher_role, school: school)
        teacher2 = create(:user, school: school, first_name: 'Anna', last_name: 'Nowak')
        UserRole.create!(user: teacher2, role: teacher_role, school: school)

        context[:params] = { search: 'Jan' }
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to contain_exactly(teacher1)
      end

      it 'supports search by email' do
        teacher1 = create(:user, school: school, email: 'jan@example.com')
        UserRole.create!(user: teacher1, role: teacher_role, school: school)
        teacher2 = create(:user, school: school, email: 'anna@example.com')
        UserRole.create!(user: teacher2, role: teacher_role, school: school)

        context[:params] = { q: 'jan@example.com' }
        result = described_class.call(context)

        expect(result).to be_success
        expect(result.form).to contain_exactly(teacher1)
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

      it 'fails with school error' do
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Brak uprawnień')
      end
    end
  end
end
