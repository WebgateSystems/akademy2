# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe BaseSidekiqJob, type: :job do
  describe 'Sidekiq configuration' do
    it 'includes Sidekiq::Job' do
      expect(described_class.included_modules).to include(Sidekiq::Job)
    end

    it 'sets default queue to :default' do
      expect(described_class.get_sidekiq_options['queue']).to eq(:default)
    end

    it 'sets default retry count to 5' do
      expect(described_class.get_sidekiq_options['retry']).to eq(5)
    end
  end

  describe 'retry delay logic (sidekiq_retry_in)' do
    it 'calculates quadratic backoff correctly' do
      expect(described_class.sidekiq_retry_in_block).not_to be_nil

      block = described_class.sidekiq_retry_in_block

      expect(block.call(1)).to eq(60)     # 1 мин (1^2 * 60)
      expect(block.call(2)).to eq(240)    # 4 мин (2^2 * 60)
      expect(block.call(3)).to eq(540)    # 9 мин (3^2 * 60)
      expect(block.call(4)).to eq(960)    # 16 мин (4^2 * 60)
      expect(block.call(5)).to eq(1500)   # 25 мин (5^2 * 60)
    end
  end

  describe 'inheritance' do
    before do
      stub_const('MyCustomJob', Class.new(BaseSidekiqJob) do
        sidekiq_options queue: :low_priority
        def perform; end
      end)
    end

    it 'allows subclasses to override queue while keeping retry settings' do
      expect(MyCustomJob.get_sidekiq_options['queue']).to eq(:low_priority)
      expect(MyCustomJob.get_sidekiq_options['retry']).to eq(5)
    end

    it 'can enqueue a subclass job' do
      expect { MyCustomJob.perform_async }.to change { MyCustomJob.jobs.size }.by(1)
    end
  end
end
