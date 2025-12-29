# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebinarRegistration do
  describe 'validations' do
    subject { build(:webinar_registration) }

    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:webinar_id) }

    it 'validates email format' do
      registration = build(:webinar_registration, email: 'invalid-email')
      expect(registration).not_to be_valid
      expect(registration.errors[:email]).to be_present
    end

    it 'validates email uniqueness per webinar' do
      create(:webinar_registration, email: 'test@example.com', webinar_id: 'webinar-1')

      duplicate = build(:webinar_registration, email: 'test@example.com', webinar_id: 'webinar-1')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include('już zapisano na ten webinar')
    end

    it 'allows same email for different webinars' do
      create(:webinar_registration, email: 'test@example.com', webinar_id: 'webinar-1')

      different_webinar = build(:webinar_registration, email: 'test@example.com', webinar_id: 'webinar-2')
      expect(different_webinar).to be_valid
    end
  end

  describe '#full_name' do
    it 'returns combined first and last name' do
      registration = build(:webinar_registration, first_name: 'Jan', last_name: 'Kowalski')
      expect(registration.full_name).to eq('Jan Kowalski')
    end
  end

  describe '#send_confirmation_email!' do
    let(:registration) { create(:webinar_registration) }

    before { allow(SendEmailJob).to receive(:enqueue) }

    it 'enqueues confirmation email' do
      registration.send_confirmation_email!

      expect(SendEmailJob).to have_received(:enqueue)
        .with('WebinarMailer', 'registration_confirmation', registration)
    end

    it 'updates confirmation_sent_at timestamp' do
      expect { registration.send_confirmation_email! }
        .to change { registration.reload.confirmation_sent_at }.from(nil)
    end

    it 'does not send email if already sent' do
      registration.update!(confirmation_sent_at: 1.hour.ago)

      registration.send_confirmation_email!

      expect(SendEmailJob).not_to have_received(:enqueue)
    end
  end
end
