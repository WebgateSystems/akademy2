# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  it 'inherits from ActiveJob::Base' do
    expect(described_class < ActiveJob::Base).to be true
  end

  it 'can enqueue a simple subclass job' do
    stub_const('TestJob', Class.new(ApplicationJob) do
      def perform; end
    end)

    expect { TestJob.perform_later }.to have_enqueued_job(TestJob)
  end

  it 'allows retry_on to be configured (commented out in base)' do
    expect(described_class).to respond_to(:retry_on)
  end

  it 'allows discard_on to be configured (commented out in base)' do
    expect(described_class).to respond_to(:discard_on)
  end
end
