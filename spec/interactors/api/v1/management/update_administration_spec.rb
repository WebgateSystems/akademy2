# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::UpdateAdministration do
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
    user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski', email: 'jan@example.com')
    UserRole.create!(user: user, role: principal_role, school: school)
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
            id: administration.id,
            administration: {
              first_name: 'Janusz',
              last_name: 'Nowak',
              metadata: {
                phone: '+48 999 888 777'
              }
            }
          }
        }
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'updates the administration' do
        result = described_class.call(context)

        expect(result).to be_success
        administration.reload
        expect(administration.first_name).to eq('Janusz')
        expect(administration.last_name).to eq('Nowak')
        expect(result.status).to eq(:ok)
        expect(result.serializer).to eq(AdministrationSerializer)
      end

      it 'merges metadata' do
        administration.update!(metadata: { phone: '+48 111 222 333' })
        context[:params][:administration][:metadata] = { address: 'Warsaw' }
        result = described_class.call(context)

        expect(result).to be_success
        administration.reload
        expect(administration.metadata['phone']).to eq('+48 111 222 333')
        expect(administration.metadata['address']).to eq('Warsaw')
      end

      it 'updates roles' do
        context[:params][:administration][:roles] = %w[principal school_manager teacher]
        result = described_class.call(context)

        expect(result).to be_success
        administration.reload
        expect(administration.user_roles.joins(:role).where(roles: { key: 'principal' },
                                                            school: school).exists?).to be true
        expect(administration.user_roles.joins(:role).where(roles: { key: 'school_manager' },
                                                            school: school).exists?).to be true
        expect(administration.user_roles.joins(:role).where(roles: { key: 'teacher' },
                                                            school: school).exists?).to be true
      end

      it 'removes teacher role when updating roles' do
        UserRole.create!(user: administration, role: teacher_role, school: school)
        context[:params][:administration][:roles] = ['principal']
        result = described_class.call(context)

        expect(result).to be_success
        administration.reload
        expect(administration.user_roles.joins(:role).where(roles: { key: 'teacher' },
                                                            school: school).exists?).to be false
      end

      it 'skips reconfirmation when email is changed' do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(User).to receive(:skip_reconfirmation!).and_call_original
        # rubocop:enable RSpec/AnyInstance
        context[:params][:administration][:email] = 'newemail@example.com'
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'fails when no administration roles are assigned' do
        context[:params][:administration][:roles] = ['teacher']
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
        expect(result.message.first).to include('przynajmniej jedną rolę administracyjną')
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

      it 'prevents self role change' do
        context[:params][:id] = school_manager.id
        context[:params][:administration][:roles] = %w[school_manager teacher]
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
        expect(result.message.first).to include('własnych uprawnień')
        expect(result.status).to eq(:forbidden)
      end

      it 'allows updating own non-role fields' do
        context[:params][:id] = school_manager.id
        context[:params][:administration].delete(:roles)
        context[:params][:administration][:first_name] = 'Updated Name'
        result = described_class.call(context)

        expect(result).to be_success
        school_manager.reload
        expect(school_manager.first_name).to eq('Updated Name')
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {
            id: administration.id,
            administration: {
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
            id: administration.id,
            administration: {
              first_name: 'Janusz'
            }
          }
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
