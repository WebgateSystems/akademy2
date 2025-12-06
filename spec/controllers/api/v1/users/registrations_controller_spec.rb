# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Users::RegistrationsController, type: :controller do
  # Since this controller isn't routed, we test the methods directly
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, school: school) }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }

  describe '#find_and_validate_invite!' do
    let(:controller_instance) { described_class.new }

    context 'when invite_token is nil' do
      before do
        allow(controller_instance).to receive(:params).and_return(ActionController::Parameters.new({}))
      end

      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          controller_instance.send(:find_and_validate_invite!)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when invite_token is blank' do
      before do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(invite_token: '')
        )
      end

      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          controller_instance.send(:find_and_validate_invite!)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when class_token is provided' do
      before do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(class_token: 'some-token')
        )
      end

      it 'calls InviteTokens::Validator with the token' do
        expect(InviteTokens::Validator).to receive(:call!).with('some-token')
        controller_instance.send(:find_and_validate_invite!)
      rescue ActiveRecord::RecordNotFound
        # Expected since the stub validator always raises
      end
    end

    context 'when invite_token is provided' do
      before do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(invite_token: 'valid-token')
        )
      end

      it 'calls InviteTokens::Validator with the token' do
        expect(InviteTokens::Validator).to receive(:call!).with('valid-token')
        controller_instance.send(:find_and_validate_invite!)
      rescue ActiveRecord::RecordNotFound
        # Expected since the stub validator always raises
      end
    end
  end

  describe '#create_teacher_role' do
    let(:controller_instance) { described_class.new }
    let(:user) { create(:user, school: school) }
    let(:invite) do
      double('Invite', kind: 'teacher', school_id: school.id, school_class_id: nil)
    end

    before do
      # Set up the resource (user) on the controller
      controller_instance.instance_variable_set(:@resource, user)
      allow(controller_instance).to receive(:resource).and_return(user)
    end

    it 'creates a UserRole with teacher role' do
      expect do
        controller_instance.create_teacher_role(invite)
      end.to change(UserRole, :count).by(1)
    end

    it 'assigns the teacher role to the user' do
      controller_instance.create_teacher_role(invite)
      expect(user.roles.map(&:key)).to include('teacher')
    end

    it 'associates the role with the correct school' do
      controller_instance.create_teacher_role(invite)
      user_role = UserRole.find_by(user: user, role: teacher_role)
      expect(user_role.school_id).to eq(school.id)
    end
  end

  describe '#create_student_enrollment' do
    let(:controller_instance) { described_class.new }
    let(:user) { create(:user, school: school) }
    let(:invite) do
      double('Invite', kind: 'student', school_id: school.id, school_class_id: school_class.id)
    end

    before do
      controller_instance.instance_variable_set(:@resource, user)
      allow(controller_instance).to receive(:resource).and_return(user)
    end

    it 'creates a StudentClassEnrollment' do
      expect do
        controller_instance.create_student_enrollment(invite)
      end.to change(StudentClassEnrollment, :count).by(1)
    end

    it 'creates enrollment with pending status' do
      controller_instance.create_student_enrollment(invite)
      enrollment = StudentClassEnrollment.find_by(student_id: user.id)
      expect(enrollment.status).to eq('pending')
    end

    it 'associates enrollment with correct class' do
      controller_instance.create_student_enrollment(invite)
      enrollment = StudentClassEnrollment.find_by(student_id: user.id)
      expect(enrollment.school_class_id).to eq(school_class.id)
    end
  end

  describe '#create_domain_links' do
    let(:controller_instance) { described_class.new }
    let(:user) { create(:user, school: school) }

    before do
      controller_instance.instance_variable_set(:@resource, user)
      allow(controller_instance).to receive(:resource).and_return(user)
    end

    context 'when invite kind is teacher' do
      let(:invite) do
        double('Invite', kind: 'teacher', school_id: school.id, school_class_id: nil)
      end

      it 'calls create_teacher_role' do
        expect(controller_instance).to receive(:create_teacher_role).with(invite)
        controller_instance.create_domain_links(invite)
      end
    end

    context 'when invite kind is student' do
      let(:invite) do
        double('Invite', kind: 'student', school_id: school.id, school_class_id: school_class.id)
      end

      it 'calls create_student_enrollment' do
        expect(controller_instance).to receive(:create_student_enrollment).with(invite)
        controller_instance.create_domain_links(invite)
      end
    end

    context 'when invite kind is unknown' do
      let(:invite) do
        double('Invite', kind: 'unknown', school_id: school.id, school_class_id: nil)
      end

      it 'does not raise error' do
        expect { controller_instance.create_domain_links(invite) }.not_to raise_error
      end
    end
  end

  describe '#sign_up_params' do
    let(:controller_instance) { described_class.new }

    before do
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          user: {
            email: 'test@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            first_name: 'John',
            last_name: 'Doe',
            locale: 'en',
            admin: true # Should be filtered out
          }
        )
      )
    end

    it 'permits email' do
      expect(controller_instance.send(:sign_up_params)[:email]).to eq('test@example.com')
    end

    it 'permits password' do
      expect(controller_instance.send(:sign_up_params)[:password]).to eq('password123')
    end

    it 'permits password_confirmation' do
      expect(controller_instance.send(:sign_up_params)[:password_confirmation]).to eq('password123')
    end

    it 'permits first_name' do
      expect(controller_instance.send(:sign_up_params)[:first_name]).to eq('John')
    end

    it 'permits last_name' do
      expect(controller_instance.send(:sign_up_params)[:last_name]).to eq('Doe')
    end

    it 'permits locale' do
      expect(controller_instance.send(:sign_up_params)[:locale]).to eq('en')
    end

    it 'filters out unpermitted params' do
      expect(controller_instance.send(:sign_up_params)[:admin]).to be_nil
    end
  end

  # NOTE: #create action cannot be unit tested directly because Devise
  # requires a proper request context with env['devise.mapping'].
  # The individual helper methods are tested above, which covers
  # the business logic. Integration testing should be done via
  # request specs once routes are properly configured.
end
