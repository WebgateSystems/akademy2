# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadVideoToYoutubeJob, type: :job do
  subject(:job) { described_class.new }

  let(:video_id) { 'test-id' }
  let(:logger)   { Rails.logger }

  before do
    allow(logger).to receive(:info)
  end

  describe '#perform' do
    # ... (существующие тесты для not_found, not_approved, already_uploaded) ...

    context 'when video is approved and not uploaded' do
      let(:video) do
        instance_double(
          StudentVideo,
          id: video_id,
          approved?: true,
          youtube_url: nil,
          file: double(path: '/tmp/video.mp4'),
          title: 'Test title',
          description: 'Test desc',
          subject_title: 'Math'
        )
      end

      let(:upload_result) { double(id: 'yt123') }
      let(:uploader)      { instance_double(YoutubeUploadService) }

      before do
        allow(StudentVideo).to receive(:find_by).and_return(video)
        allow(YoutubeUploadService).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:call).and_return(upload_result)
        allow(video).to receive(:update!)
      end

      it 'uploads video and updates record' do
        job.perform(video_id)

        expect(YoutubeUploadService).to have_received(:new).with(
          file_path: '/tmp/video.mp4',
          title: 'Test title',
          description: 'Test desc',
          tags: ['Math', 'Akademy2.0']
        )

        expect(video).to have_received(:update!).with(
          hash_including(
            youtube_url: 'https://youtu.be/yt123',
            youtube_id: 'yt123'
          )
        )

        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[success\].*Uploaded to YouTube: yt123/)
      end
    end

    describe 'error handling' do
      let(:video) do
        instance_double(
          StudentVideo,
          id: video_id,
          approved?: true,
          youtube_url: nil,
          file: double(path: '/tmp/video.mp4'),
          title: 'Test', description: 'Test', subject_title: 'Test'
        )
      end
      let(:uploader) { instance_double(YoutubeUploadService) }

      before do
        allow(StudentVideo).to receive(:find_by).and_return(video)
        allow(YoutubeUploadService).to receive(:new).and_return(uploader)
      end

      it 'handles Google::Apis::ServerError' do
        allow(uploader).to receive(:call).and_raise(Google::Apis::ServerError.new('server error'))

        expect { job.perform(video_id) }.to raise_error(Google::Apis::ServerError)
        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[api_error\].*YouTube API error: server error/)
      end

      it 'handles Google::Apis::ClientError' do
        allow(uploader).to receive(:call).and_raise(Google::Apis::ClientError.new('client error'))

        expect { job.perform(video_id) }.to raise_error(Google::Apis::ClientError)
        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[api_error\].*YouTube API error: client error/)
      end

      it 'handles unexpected StandardError' do
        allow(uploader).to receive(:call).and_raise(StandardError.new('something went wrong'))

        expect { job.perform(video_id) }.to raise_error(StandardError)
        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[unexpected\].*Unexpected error: StandardError – something went wrong/)
      end

      it 'handles Signet::AuthorizationError' do
        allow(uploader).to receive(:call).and_raise(Signet::AuthorizationError.new('auth fail'))

        expect { job.perform(video_id) }.to raise_error(Signet::AuthorizationError)
        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[auth_error\].*Authorization failed: auth fail/)
      end
    end
  end

  describe 'sidekiq configuration' do
    it 'uses default queue and 5 retries' do
      # В некоторых версиях sidekiq/rspec используется sidekiq_options_hash
      options = described_class.get_sidekiq_options
      expect(options['queue']).to eq(:default)
      expect(options['retry']).to eq(5)
    end
  end
end
