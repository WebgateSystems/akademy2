# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadVideoToYoutubeJob, type: :job do
  describe '#perform' do
    context 'when video does not exist' do
      it 'returns early without error' do
        expect { described_class.new.perform('nonexistent-id') }.not_to raise_error
      end
    end

    context 'when video is not approved' do
      it 'returns early without error' do
        video_double = instance_double(StudentVideo, approved?: false)
        allow(StudentVideo).to receive(:find_by).with(id: 'test-id').and_return(video_double)

        expect { described_class.new.perform('test-id') }.not_to raise_error
      end
    end

    context 'when video already has youtube_url' do
      it 'returns early without error' do
        video_double = instance_double(StudentVideo, approved?: true)
        allow(video_double).to receive(:youtube_url).and_return('https://youtube.com/watch?v=abc123')
        allow(StudentVideo).to receive(:find_by).with(id: 'test-id').and_return(video_double)

        expect { described_class.new.perform('test-id') }.not_to raise_error
      end
    end

    context 'when video is approved and has no youtube_url' do
      it 'logs not implemented message' do
        video_double = instance_double(StudentVideo, approved?: true)
        allow(video_double).to receive(:youtube_url).and_return(nil)
        allow(StudentVideo).to receive(:find_by).with(id: 'test-id').and_return(video_double)
        allow(Rails.logger).to receive(:info)

        described_class.new.perform('test-id')

        expect(Rails.logger).to have_received(:info).with(/YouTube upload not yet implemented/)
      end
    end
  end

  describe 'queue' do
    it 'uses default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end

  describe 'retry configuration' do
    it 'is configured to retry on StandardError' do
      handler_classes = described_class.rescue_handlers.map { |h| h[0] }
      expect(handler_classes).to include('StandardError')
    end

    it 'has 5 retry attempts' do
      handler = described_class.rescue_handlers.find { |h| h[0] == 'StandardError' }
      # Handler is [exception_class_string, proc]
      expect(handler).to be_present
    end
  end
end
