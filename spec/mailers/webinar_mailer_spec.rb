# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebinarMailer do
  describe '#registration_confirmation' do
    let(:registration) { create(:webinar_registration, first_name: 'Jan', email: 'jan@example.com') }
    let(:mail) { described_class.registration_confirmation(registration) }

    it 'sends to the registration email' do
      expect(mail.to).to eq(['jan@example.com'])
    end

    it 'has correct subject' do
      expect(mail.subject).to include('Potwierdzenie rejestracji')
      expect(mail.subject).to include('webinar')
    end

    it 'includes recipient name in body' do
      expect(mail.body.encoded).to include('Jan')
    end

    it 'includes Zoom link' do
      expect(mail.body.encoded).to include('zoom.us')
    end

    it 'includes Google Meet link' do
      expect(mail.body.encoded).to include('meet.google.com')
    end

    it 'includes meeting credentials' do
      expect(mail.body.encoded).to include('962 5894 4674') # Meeting ID
      expect(mail.body.encoded).to include('902114') # Passcode
    end

    it 'includes webinar date and time' do
      expect(mail.body.encoded).to include('29 grudnia 2025')
      expect(mail.body.encoded).to include('17:00')
    end
  end
end
