# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CustomDeviseMailer, type: :mailer do
  let(:school) { create(:school) }
  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  describe '#reset_password_instructions' do
    let(:token) { 'reset_token_123' }

    context 'when user is a student' do
      let(:student) do
        user = create(:user, school: school, first_name: 'Jan')
        UserRole.create!(user: user, role: student_role, school: school)
        user.reload
      end

      it 'sends email to student' do
        mail = described_class.reset_password_instructions(student, token)

        expect(mail.to).to eq([student.email])
      end

      it 'includes PIN advice for students' do
        mail = described_class.reset_password_instructions(student, token)

        expect(mail.body.encoded).to include('PIN')
        expect(mail.body.encoded).to include('4 cyfry')
      end

      it 'does not include 12 character advice' do
        mail = described_class.reset_password_instructions(student, token)

        expect(mail.body.encoded).not_to include('12 znaków')
      end

      it 'includes student role in reset URL' do
        mail = described_class.reset_password_instructions(student, token)

        expect(mail.body.encoded).to include('role=student')
      end
    end

    context 'when user is a teacher' do
      let(:teacher) do
        user = create(:user, school: school, first_name: 'Anna')
        UserRole.create!(user: user, role: teacher_role, school: school)
        user.reload
      end

      it 'sends email to teacher' do
        mail = described_class.reset_password_instructions(teacher, token)

        expect(mail.to).to eq([teacher.email])
      end

      it 'includes 12 character advice for non-students' do
        mail = described_class.reset_password_instructions(teacher, token)

        expect(mail.body.encoded).to include('12 znaków')
      end

      it 'does not include PIN advice' do
        mail = described_class.reset_password_instructions(teacher, token)

        expect(mail.body.encoded).not_to include('4 cyfry')
      end
    end

    context 'with any user' do
      let(:user) { create(:user, school: school, first_name: 'Test') }

      it 'has correct reply_to header' do
        mail = described_class.reset_password_instructions(user, token)

        expect(mail.reply_to).to eq([Settings.services.smtp.reply_to])
      end

      it 'includes text logo in header' do
        mail = described_class.reset_password_instructions(user, token)

        expect(mail.body.encoded).to include('AKA')
        expect(mail.body.encoded).to include('demy')
      end

      it 'includes Webgate Systems LTD copyright' do
        mail = described_class.reset_password_instructions(user, token)

        expect(mail.body.encoded).to include('Webgate Systems LTD')
        expect(mail.body.encoded).to include('webgate.pro')
      end

      it 'includes AGPLv3 license link' do
        mail = described_class.reset_password_instructions(user, token)

        expect(mail.body.encoded).to include('AGPLv3')
        expect(mail.body.encoded).to include('gnu.org/licenses/agpl')
      end

      it 'uses blue accent color for buttons' do
        mail = described_class.reset_password_instructions(user, token)

        expect(mail.body.encoded).to include('#4A90E2')
      end

      it 'uses gray background for header' do
        mail = described_class.reset_password_instructions(user, token)

        expect(mail.body.encoded).to include('#F0F0F0')
      end

      it 'includes user first name in greeting' do
        mail = described_class.reset_password_instructions(user, token)

        expect(mail.body.encoded).to include('Test')
      end
    end
  end

  describe '#confirmation_instructions' do
    let(:user) { create(:user, school: school, first_name: 'Ewa') }
    let(:token) { 'confirm_token_456' }

    it 'sends confirmation email' do
      mail = described_class.confirmation_instructions(user, token)

      expect(mail.to).to eq([user.email])
    end

    it 'includes welcome message' do
      mail = described_class.confirmation_instructions(user, token)

      expect(mail.body.encoded).to include('Witaj w AKAdemy')
    end

    it 'includes feature list' do
      mail = described_class.confirmation_instructions(user, token)

      expect(mail.body.encoded).to include('Tematy i moduły')
      expect(mail.body.encoded).to include('Quizy z certyfikatem')
      expect(mail.body.encoded).to include('Tryb offline')
    end

    it 'includes text logo in header' do
      mail = described_class.confirmation_instructions(user, token)

      expect(mail.body.encoded).to include('AKA')
      expect(mail.body.encoded).to include('demy')
    end
  end

  describe '#unlock_instructions' do
    let(:user) { create(:user, school: school, first_name: 'Piotr') }
    let(:token) { 'unlock_token_789' }

    it 'sends unlock email' do
      mail = described_class.unlock_instructions(user, token)

      expect(mail.to).to eq([user.email])
    end

    it 'includes lock message' do
      mail = described_class.unlock_instructions(user, token)

      expect(mail.body.encoded).to include('zablokowane')
    end

    it 'includes security advice' do
      mail = described_class.unlock_instructions(user, token)

      expect(mail.body.encoded).to include('Bezpieczeństwo')
    end
  end
end
