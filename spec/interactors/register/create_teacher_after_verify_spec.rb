# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::CreateTeacherAfterVerify do
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
  let(:school) { create(:school) }
  let(:school_manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: school_manager_role, school: school)
    user
  end

  before do
    teacher_role
    school_manager_role
  end

  describe '#call' do
    context 'when registering without a school (no join_token)' do
      let(:flow) do
        instance_double(
          Register::WizardFlow,
          :[] => nil,
          'data' => {}
        )
      end

      before do
        allow(flow).to receive(:[]).with('profile').and_return({
                                                                 'first_name' => 'Jan',
                                                                 'last_name' => 'Kowalski',
                                                                 'email' => 'jan.kowalski@example.com',
                                                                 'phone' => '+48123456789',
                                                                 'password' => 'password123',
                                                                 'password_confirmation' => 'password123'
                                                               })
        allow(flow).to receive(:[]).with('school').and_return(nil)
      end

      it 'creates a new user' do
        expect do
          described_class.call(flow: flow)
        end.to change(User, :count).by(1)
      end

      it 'assigns teacher role without school' do
        result = described_class.call(flow: flow)

        expect(result).to be_success
        expect(result.user.roles.pluck(:key)).to include('teacher')

        teacher_user_role = result.user.user_roles.joins(:role).find_by(roles: { key: 'teacher' })
        expect(teacher_user_role.school_id).to be_nil
      end

      it 'does not create any enrollment' do
        expect do
          described_class.call(flow: flow)
        end.not_to change(TeacherSchoolEnrollment, :count)
      end
    end

    context 'when registering with a school (with join_token)' do
      let(:flow) do
        instance_double(
          Register::WizardFlow,
          :[] => nil,
          'data' => {}
        )
      end

      before do
        allow(flow).to receive(:[]).with('profile').and_return({
                                                                 'first_name' => 'Jan',
                                                                 'last_name' => 'Kowalski',
                                                                 'email' => 'jan.kowalski@example.com',
                                                                 'phone' => '+48123456789',
                                                                 'password' => 'password123',
                                                                 'password_confirmation' => 'password123'
                                                               })
        allow(flow).to receive(:[]).with('school').and_return({
                                                                'join_token' => school.join_token
                                                              })
      end

      it 'creates a new user' do
        expect do
          described_class.call(flow: flow)
        end.to change(User, :count).by(1)
      end

      it 'assigns teacher role without school (pending approval)' do
        result = described_class.call(flow: flow)

        expect(result).to be_success
        expect(result.user.roles.pluck(:key)).to include('teacher')

        teacher_user_role = result.user.user_roles.joins(:role).find_by(roles: { key: 'teacher' })
        expect(teacher_user_role.school_id).to be_nil
      end

      it 'creates a pending enrollment' do
        expect do
          described_class.call(flow: flow)
        end.to change(TeacherSchoolEnrollment, :count).by(1)
      end

      it 'creates enrollment with pending status' do
        result = described_class.call(flow: flow)

        enrollment = TeacherSchoolEnrollment.find_by(teacher: result.user, school: school)
        expect(enrollment).to be_present
        expect(enrollment.status).to eq('pending')
      end

      it 'creates notification for school managers' do
        # Ensure school_manager exists before the test
        school_manager
        expect do
          described_class.call(flow: flow)
        end.to change(Notification, :count).by(1)
      end
    end

    context 'when user already exists' do
      let!(:existing_user) do
        create(:user, email: 'existing@example.com', password: 'Password1', password_confirmation: 'Password1')
      end
      let(:flow) do
        instance_double(
          Register::WizardFlow,
          :[] => nil,
          'data' => {}
        )
      end

      before do
        allow(flow).to receive(:[]).with('profile').and_return({
                                                                 'first_name' => 'Updated',
                                                                 'last_name' => 'Name',
                                                                 'email' => 'existing@example.com',
                                                                 'phone' => '+48999888777',
                                                                 'password' => 'newpassword123',
                                                                 'password_confirmation' => 'newpassword123'
                                                               })
        allow(flow).to receive(:[]).with('school').and_return({
                                                                'join_token' => school.join_token
                                                              })
      end

      it 'does not create a new user' do
        expect do
          described_class.call(flow: flow)
        end.not_to change(User, :count)
      end

      it 'updates existing user details' do
        described_class.call(flow: flow)
        existing_user.reload

        expect(existing_user.first_name).to eq('Updated')
        expect(existing_user.last_name).to eq('Name')
        expect(existing_user.phone).to eq('+48999888777')
      end

      it 'assigns teacher role to existing user' do
        described_class.call(flow: flow)
        existing_user.reload

        expect(existing_user.roles.pluck(:key)).to include('teacher')
      end

      it 'creates pending enrollment for existing user' do
        expect do
          described_class.call(flow: flow)
        end.to change(TeacherSchoolEnrollment, :count).by(1)
      end
    end

    context 'when enrollment already exists' do
      let!(:teacher) do
        user = create(:user, email: 'teacher@example.com')
        UserRole.create!(user: user, role: teacher_role, school: nil)
        user
      end
      let!(:existing_enrollment) do
        TeacherSchoolEnrollment.create!(
          teacher: teacher,
          school: school,
          status: 'pending'
        )
      end
      let(:flow) do
        instance_double(
          Register::WizardFlow,
          :[] => nil,
          'data' => {}
        )
      end

      before do
        allow(flow).to receive(:[]).with('profile').and_return({
                                                                 'first_name' => 'Jan',
                                                                 'last_name' => 'Kowalski',
                                                                 'email' => 'teacher@example.com',
                                                                 'phone' => '+48123456789',
                                                                 'password' => 'password123',
                                                                 'password_confirmation' => 'password123'
                                                               })
        allow(flow).to receive(:[]).with('school').and_return({
                                                                'join_token' => school.join_token
                                                              })
      end

      it 'does not create duplicate enrollment' do
        expect do
          described_class.call(flow: flow)
        end.not_to change(TeacherSchoolEnrollment, :count)
      end
    end
  end
end
