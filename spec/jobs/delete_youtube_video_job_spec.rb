# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteYoutubeVideoJob, type: :job do
  subject(:job) { described_class.new }

  let(:student_video_id) { 'sv_123' }
  let(:youtube_id) { 'yt_123' }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    it 'logs success result' do
      service = instance_double(YoutubeDeleteService, call: :deleted)
      allow(YoutubeDeleteService).to receive(:new).with(youtube_id: youtube_id).and_return(service)

      job.perform(student_video_id, youtube_id)

      expect(Rails.logger).to have_received(:info)
        .with(/\[YouTubeDelete\] \[deleted\] StudentVideo##{student_video_id}/)
    end

    context 'when Google API returns insufficient scopes error' do
      let(:google_error) do
        Google::Apis::ClientError.new('insufficient authentication scopes')
      end

      before do
        allow(YoutubeDeleteService).to receive(:new).and_raise(google_error)
      end

      it 'logs specific error and does NOT re-raise (stops retries)' do
        expect { job.perform(student_video_id, youtube_id) }.not_to raise_error

        expect(Rails.logger).to have_received(:error)
          .with(/\[YouTubeDelete\] \[insufficient_scopes\] StudentVideo##{student_video_id}/)
      end
    end

    context 'when Google API returns other client error' do
      let(:google_error) { Google::Apis::ClientError.new('some other error') }

      before do
        allow(YoutubeDeleteService).to receive(:new).and_raise(google_error)
      end

      it 're-raises the error to allow Sidekiq retry' do
        expect { job.perform(student_video_id, youtube_id) }.to raise_error(Google::Apis::ClientError)
      end
    end

    it 're-raises standard errors and logs failure' do
      allow(YoutubeDeleteService).to receive(:new).and_raise(StandardError, 'boom')

      expect { job.perform(student_video_id, youtube_id) }.to raise_error(StandardError, 'boom')
      expect(Rails.logger).to have_received(:error)
        .with(/\[YouTubeDelete\] \[fail\] StudentVideo##{student_video_id}.*boom/)
    end
  end

  describe 'sidekiq options' do
    it 'is in the internal queue' do
      expect(described_class.sidekiq_options['queue']).to eq(:internal)
    end

    it 'has 5 retries' do
      expect(described_class.sidekiq_options['retry']).to eq(5)
    end
  end
end
