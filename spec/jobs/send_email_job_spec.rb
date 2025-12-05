# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendEmailJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:token) { 'reset_token_123' }
    let(:mail_double) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(CustomDeviseMailer).to receive(:reset_password_instructions)
        .and_return(mail_double)
      allow(mail_double).to receive(:deliver_now)
    end

    it 'calls the specified mailer with the given action and arguments' do
      described_class.perform_now('CustomDeviseMailer', 'reset_password_instructions', user, token, {})

      expect(CustomDeviseMailer).to have_received(:reset_password_instructions)
        .with(user, token, {})
    end

    it 'delivers the email immediately' do
      described_class.perform_now('CustomDeviseMailer', 'reset_password_instructions', user, token, {})

      expect(mail_double).to have_received(:deliver_now)
    end

    it 'queues the job in the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end

    context 'with different mailer classes' do
      let(:test_mail) { instance_double(ActionMailer::MessageDelivery) }
      let(:mock_mailer) do
        Class.new do
          def self.welcome_email(*); end
        end
      end

      before do
        stub_const('TestMailer', mock_mailer)
        allow(mock_mailer).to receive(:welcome_email).and_return(test_mail)
        allow(test_mail).to receive(:deliver_now)
      end

      it 'works with any mailer class' do
        described_class.perform_now('TestMailer', 'welcome_email', user.id)

        expect(mock_mailer).to have_received(:welcome_email).with(user.id)
        expect(test_mail).to have_received(:deliver_now)
      end
    end

    context 'with multiple arguments' do
      before do
        allow(CustomDeviseMailer).to receive(:confirmation_instructions)
          .and_return(mail_double)
      end

      it 'passes all arguments to the mailer' do
        opts = { from: 'noreply@example.com' }
        described_class.perform_now('CustomDeviseMailer', 'confirmation_instructions', user, token, opts)

        expect(CustomDeviseMailer).to have_received(:confirmation_instructions)
          .with(user, token, opts)
      end
    end
  end

  describe 'job enqueuing' do
    let(:user) { create(:user) }

    it 'enqueues the job' do
      expect do
        described_class.perform_later('CustomDeviseMailer', 'reset_password_instructions', user, 'token', {})
      end.to have_enqueued_job(described_class)
    end

    it 'enqueues with correct arguments' do
      expect do
        described_class.perform_later('CustomDeviseMailer', 'reset_password_instructions', user, 'token', {})
      end.to have_enqueued_job(described_class)
        .with('CustomDeviseMailer', 'reset_password_instructions', user, 'token', {})
    end

    it 'enqueues in the default queue' do
      expect do
        described_class.perform_later('CustomDeviseMailer', 'reset_password_instructions', user, 'token', {})
      end.to have_enqueued_job(described_class).on_queue('default')
    end
  end
end
