# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::SetPinConfirmSubmit do
  describe '#call' do
    let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }

    let(:flow) do
      flow = Register::WizardFlow.new({})
      flow.update(:profile, {
                    'first_name' => 'John',
                    'last_name' => 'Doe',
                    'birthdate' => '1990-01-15',
                    'email' => "test_#{SecureRandom.hex(4)}@example.com"
                  })
      flow.update(:phone, { 'phone' => "+48#{rand(100_000_000..999_999_999)}", 'verified' => true })
      flow.update(:pin_temp, { 'pin' => '1234' })
      flow
    end

    context 'when PIN matches' do
      let(:matching_params) { { pin_hidden: '1234' } }

      it 'succeeds' do
        result = described_class.call(params: matching_params, flow: flow)

        expect(result).to be_success
      end

      it 'creates user' do
        expect do
          described_class.call(params: matching_params, flow: flow)
        end.to change(User, :count).by(1)
      end

      it 'assigns student role' do
        described_class.call(params: matching_params, flow: flow)

        user_id = flow['user']['user_id']
        user = User.find(user_id)
        expect(user.roles.pluck(:key)).to include('student')
      end

      it 'stores user_id in flow' do
        described_class.call(params: matching_params, flow: flow)

        expect(flow['user']['user_id']).to be_present
      end

      it 'stores confirmed PIN in flow' do
        described_class.call(params: matching_params, flow: flow)

        expect(flow['pin']['pin']).to eq('1234')
      end
    end

    context 'when PIN does not match' do
      let(:mismatched_params) { { pin_hidden: '9999' } }

      it 'fails with mismatch message' do
        result = described_class.call(params: mismatched_params, flow: flow)

        expect(result).to be_failure
        expect(result.message).to eq('Codes do not match')
      end

      it 'does not create user' do
        expect do
          described_class.call(params: mismatched_params, flow: flow)
        end.not_to change(User, :count)
      end
    end

    context 'when user creation fails' do
      let(:matching_params) { { pin_hidden: '1234' } }

      before do
        # Use email that already exists
        create(:user, email: flow['profile']['email'])
      end

      it 'fails with user errors' do
        result = described_class.call(params: matching_params, flow: flow)

        expect(result).to be_failure
        expect(result.message).to include('Email')
      end

      it 'sets redirect path' do
        result = described_class.call(params: matching_params, flow: flow)

        expect(result.redirect_path).to eq('/register/profile')
      end
    end

    context 'with teacher registration' do
      let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
      let(:school) { create(:school) }
      let(:matching_params) { { pin_hidden: '1234' } }

      before do
        flow.data['registration_type'] = 'teacher'
        flow.update(:school, { 'school_id' => school.id })
        allow(NotificationService).to receive(:create_teacher_enrollment_request)
      end

      it 'assigns teacher role' do
        result = described_class.call(params: matching_params, flow: flow)

        expect(result).to be_success
        user_id = flow['user']['user_id']
        user = User.find(user_id)
        expect(user.roles.pluck(:key)).to include('teacher')
      end

      it 'creates pending enrollment' do
        expect do
          described_class.call(params: matching_params, flow: flow)
        end.to change(TeacherSchoolEnrollment, :count).by(1)
      end

      it 'creates notification' do
        described_class.call(params: matching_params, flow: flow)

        expect(NotificationService).to have_received(:create_teacher_enrollment_request)
      end
    end

    context 'with student registration and class token' do
      let(:school) { create(:school) }
      let(:school_class) { create(:school_class, school: school) }
      let(:matching_params) { { pin_hidden: '1234' } }

      before do
        flow.data['registration_type'] = 'student'
        flow.update(:school_class, {
                      'join_token' => school_class.join_token,
                      'school_class_id' => school_class.id,
                      'school_id' => school.id
                    })
        flow.update(:school, { 'school_id' => school.id })
        allow(NotificationService).to receive(:create_student_enrollment_request)
      end

      it 'assigns student role with school' do
        result = described_class.call(params: matching_params, flow: flow)

        expect(result).to be_success
        user_id = flow['user']['user_id']
        user = User.find(user_id)
        expect(user.roles.pluck(:key)).to include('student')
        expect(user.school).to eq(school)
      end

      it 'creates pending enrollment' do
        expect do
          described_class.call(params: matching_params, flow: flow)
        end.to change(StudentClassEnrollment, :count).by(1)
      end

      it 'creates enrollment with pending status' do
        described_class.call(params: matching_params, flow: flow)

        user_id = flow['user']['user_id']
        user = User.find(user_id)
        enrollment = StudentClassEnrollment.find_by(student: user, school_class: school_class)
        expect(enrollment.status).to eq('pending')
      end

      it 'creates notification' do
        described_class.call(params: matching_params, flow: flow)

        expect(NotificationService).to have_received(:create_student_enrollment_request)
      end
    end

    context 'with student registration without class token' do
      let(:matching_params) { { pin_hidden: '1234' } }

      before do
        flow.data['registration_type'] = 'student'
      end

      it 'assigns student role without school' do
        result = described_class.call(params: matching_params, flow: flow)

        expect(result).to be_success
        user_id = flow['user']['user_id']
        user = User.find(user_id)
        expect(user.roles.pluck(:key)).to include('student')
        expect(user.school).to be_nil
      end

      it 'does not create enrollment' do
        expect do
          described_class.call(params: matching_params, flow: flow)
        end.not_to change(StudentClassEnrollment, :count)
      end
    end

    context 'when student has school but no class (should not be teacher)' do
      let(:school) { create(:school) }
      let(:matching_params) { { pin_hidden: '1234' } }

      before do
        flow.data['registration_type'] = 'student'
        flow.update(:school, { 'school_id' => school.id })
        # No school_class data
      end

      it 'assigns student role, not teacher role' do
        result = described_class.call(params: matching_params, flow: flow)

        expect(result).to be_success
        user_id = flow['user']['user_id']
        user = User.find(user_id)
        expect(user.roles.pluck(:key)).to include('student')
        expect(user.roles.pluck(:key)).not_to include('teacher')
      end
    end
  end
end
