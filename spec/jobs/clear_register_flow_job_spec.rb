# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClearRegisterFlowJob, type: :job do
  describe '#perform' do
    it 'destroys all registration flows' do
      allow(RegistrationFlow).to receive(:destroy_all)

      described_class.new.perform

      expect(RegistrationFlow).to have_received(:destroy_all)
    end
  end

  describe 'queue' do
    it 'uses default queue' do
      expect(described_class.sidekiq_options['queue']).to eq(:default)
    end
  end
end
