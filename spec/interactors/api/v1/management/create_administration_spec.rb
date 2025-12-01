# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Management::CreateAdministration do
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
    # Create principal before creating notifications
    principal_user = create(:user, school: school)
    UserRole.create!(user: principal_user, role: principal_role, school: school)
    school_manager.reload
  end

  describe '#call' do
    context 'when user is authorized' do
      let(:context) do
        {
          current_user: school_manager,
          params: {
            administration: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              roles: %w[principal teacher],
              metadata: {
                phone: '+48 123 456 789'
              }
            }
          }
        }
      end

      it 'succeeds' do
        result = described_class.call(context)
        expect(result).to be_success
      end

      it 'creates administration user' do
        expect do
          described_class.call(context)
        end.to change(User, :count).by(1)
      end

      it 'assigns principal role' do
        result = described_class.call(context)
        admin = result.form.reload
        expect(admin.user_roles.joins(:role).where(roles: { key: 'principal' }, school: school).exists?).to be true
      end

      it 'assigns teacher role' do
        result = described_class.call(context)
        admin = result.form.reload
        expect(admin.user_roles.joins(:role).where(roles: { key: 'teacher' }, school: school).exists?).to be true
      end

      it 'assigns user to school' do
        result = described_class.call(context)
        admin = result.form
        expect(admin.school_id).to eq(school.id)
      end

      it 'generates password if not provided' do
        result = described_class.call(context)
        admin = result.form.reload
        expect(admin.encrypted_password).to be_present
      end

      it 'creates notification' do
        expect do
          described_class.call(context)
        end.to change(Notification, :count).by_at_least(1)

        notification = Notification.find_by(
          notification_type: 'teacher_awaiting_approval',
          school: school
        )
        expect(notification).to be_present
      end

      it 'sets serializer and status' do
        result = described_class.call(context)
        expect(result.serializer).to eq(AdministrationSerializer)
        expect(result.status).to eq(:created)
      end

      it 'creates administration with school_manager role' do
        context[:params][:administration][:roles] = ['school_manager']
        result = described_class.call(context)
        admin = result.form.reload
        expect(admin.user_roles.joins(:role).where(roles: { key: 'school_manager' }, school: school).exists?).to be true
      end

      it 'creates administration with all three roles' do
        context[:params][:administration][:roles] = %w[principal school_manager teacher]
        result = described_class.call(context)
        admin = result.form.reload
        expect(admin.user_roles.joins(:role).where(roles: { key: 'principal' }, school: school).exists?).to be true
        expect(admin.user_roles.joins(:role).where(roles: { key: 'school_manager' }, school: school).exists?).to be true
        expect(admin.user_roles.joins(:role).where(roles: { key: 'teacher' }, school: school).exists?).to be true
      end

      it 'handles metadata correctly' do
        result = described_class.call(context)
        admin = result.form.reload
        expect(admin.metadata['phone']).to eq('+48 123 456 789')
      end

      it 'fails when email is missing' do
        context[:params][:administration].delete(:email)
        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
      end

      it 'succeeds even when first_name is missing (not required by model)' do
        context[:params][:administration].delete(:first_name)
        result = described_class.call(context)

        # first_name is not required by User model, so it should succeed
        expect(result).to be_success
      end

      it 'succeeds even when last_name is missing (not required by model)' do
        context[:params][:administration].delete(:last_name)
        result = described_class.call(context)

        # last_name is not required by User model, so it should succeed
        expect(result).to be_success
      end

      it 'fails when email is duplicate' do
        existing_admin = create(:user, email: 'jan.kowalski@example.com', school: school)
        UserRole.create!(user: existing_admin, role: principal_role, school: school)

        result = described_class.call(context)

        expect(result).to be_failure
        expect(result.message).to be_an(Array)
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user, school: school) }
      let(:context) do
        {
          current_user: unauthorized_user,
          params: {
            administration: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              roles: ['principal']
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
            administration: {
              first_name: 'Jan',
              last_name: 'Kowalski',
              email: 'jan.kowalski@example.com',
              roles: ['principal']
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
