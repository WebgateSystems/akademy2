# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::UpdateTeacher do
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end
  let(:teacher) do
    user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski', email: 'jan@example.com')
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
          params: {
            id: teacher.id,
            teacher: {
              first_name: 'Janusz',
              last_name: 'Nowak'
            }
          }
        }
      end

      it 'updates the teacher' do
        result = described_class.call(context)

        expect(result).to be_success
        teacher.reload
        expect(teacher.first_name).to eq('Janusz')
        expect(teacher.last_name).to eq('Nowak')
        expect(result.status).to eq(:ok)
        expect(result.serializer).to eq(TeacherSerializer)
      end

      it 'merges metadata' do
        teacher.update!(metadata: { phone: '+48 111 222 333' })
        context[:params][:teacher][:metadata] = { address: 'Warsaw' }
        result = described_class.call(context)

        expect(result).to be_success
        teacher.reload
        expect(teacher.metadata['phone']).to eq('+48 111 222 333')
        expect(teacher.metadata['address']).to eq('Warsaw')
      end

      it 'skips reconfirmation when email is changed' do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(User).to receive(:skip_reconfirmation!).and_call_original
        # rubocop:enable RSpec/AnyInstance
        context[:params][:teacher][:email] = 'newemail@example.com'
        result = described_class.call(context)
        expect(result).to be_success
      end

      context 'with password change' do
        it 'changes password when password and confirmation are provided' do
          context[:params][:teacher][:password] = 'newpassword123'
          context[:params][:teacher][:password_confirmation] = 'newpassword123'
          result = described_class.call(context)

          expect(result).to be_success
          teacher.reload
          expect(teacher.valid_password?('newpassword123')).to be true
        end

        it 'does not change password when password is blank' do
          old_password = teacher.encrypted_password
          context[:params][:teacher][:password] = ''
          context[:params][:teacher][:password_confirmation] = ''
          result = described_class.call(context)

          expect(result).to be_success
          teacher.reload
          expect(teacher.encrypted_password).to eq(old_password)
        end

        it 'does not change password when password is not provided' do
          old_password = teacher.encrypted_password
          result = described_class.call(context)

          expect(result).to be_success
          teacher.reload
          expect(teacher.encrypted_password).to eq(old_password)
        end

        it 'fails when password and confirmation do not match' do
          context[:params][:teacher][:password] = 'newpassword123'
          context[:params][:teacher][:password_confirmation] = 'differentpassword'
          result = described_class.call(context)

          expect(result).to be_failure
        end
      end

      it 'fails when teacher does not exist' do
        context[:params][:id] = SecureRandom.uuid
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Nauczyciel nie został znaleziony')
        expect(result.status).to eq(:not_found)
      end

      it 'fails when teacher belongs to another school' do
        other_school = create(:school)
        other_teacher = create(:user, school: other_school)
        UserRole.create!(user: other_teacher, role: teacher_role, school: other_school)

        context[:params][:id] = other_teacher.id
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to include('Nauczyciel nie został znaleziony')
      end

      context 'with is_school_manager flag' do
        it 'promotes teacher to school_manager when is_school_manager is true' do
          context[:params][:teacher][:is_school_manager] = true
          result = described_class.call(context)

          expect(result).to be_success
          teacher.reload
          expect(teacher.user_roles.joins(:role).where(roles: { key: 'school_manager' }, school: school).count).to eq(1)
        end

        it 'demotes teacher from school_manager when is_school_manager is false' do
          # First promote the teacher
          UserRole.create!(user: teacher, role: school_manager_role, school: school)
          expect(teacher.user_roles.joins(:role).where(roles: { key: 'school_manager' }).count).to eq(1)

          context[:params][:teacher][:is_school_manager] = false
          result = described_class.call(context)

          expect(result).to be_success
          teacher.reload
          expect(teacher.user_roles.joins(:role).where(roles: { key: 'school_manager' }).count).to eq(0)
        end

        it 'does not change school_manager role when is_school_manager is not specified' do
          # Teacher without school_manager role
          expect(teacher.user_roles.joins(:role).where(roles: { key: 'school_manager' }).count).to eq(0)

          # Update without is_school_manager
          result = described_class.call(context)

          expect(result).to be_success
          teacher.reload
          expect(teacher.user_roles.joins(:role).where(roles: { key: 'school_manager' }).count).to eq(0)
        end

        it 'preserves teacher role when promoting to school_manager' do
          context[:params][:teacher][:is_school_manager] = true
          result = described_class.call(context)

          expect(result).to be_success
          teacher.reload
          expect(teacher.user_roles.joins(:role).where(roles: { key: 'teacher' }, school: school).count).to eq(1)
          expect(teacher.user_roles.joins(:role).where(roles: { key: 'school_manager' }, school: school).count).to eq(1)
        end
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {
            id: teacher.id,
            teacher: {
              first_name: 'Janusz'
            }
          }
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
          params: {
            id: teacher.id,
            teacher: {
              first_name: 'Janusz'
            }
          }
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
