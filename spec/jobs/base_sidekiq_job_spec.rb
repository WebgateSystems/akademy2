# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe BaseSidekiqJob, type: :job do
  it 'includes Sidekiq::Job' do
    expect(described_class.included_modules).to include(Sidekiq::Job)
  end

  it 'sets default queue to :default' do
    expect(described_class.get_sidekiq_options['queue']).to eq(:default)
  end

  it 'sets default retry count to 5' do
    expect(described_class.get_sidekiq_options['retry']).to eq(5)
  end

  it 'can enqueue a simple subclass job' do
    stub_const('TestSidekiqJob', Class.new(BaseSidekiqJob) do
      def perform; end
    end)

    expect { TestSidekiqJob.perform_async }.to change { TestSidekiqJob.jobs.size }.by(1)
  end
end
