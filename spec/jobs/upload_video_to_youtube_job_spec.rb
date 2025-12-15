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
    context 'when video does not exist' do
      it 'logs not_found and exits' do
        allow(StudentVideo).to receive(:find_by).with(id: video_id).and_return(nil)

        expect { job.perform(video_id) }.not_to raise_error

        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[not_found\].*Video not found/)
      end
    end

    context 'when video is not approved' do
      let(:video) { instance_double(StudentVideo, id: video_id, approved?: false) }

      it 'logs not_approved and exits' do
        allow(StudentVideo).to receive(:find_by).and_return(video)

        expect { job.perform(video_id) }.not_to raise_error

        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[not_approved\].*Not approved/)
      end
    end

    context 'when video already uploaded' do
      let(:video) do
        instance_double(
          StudentVideo,
          id: video_id,
          approved?: true,
          youtube_url: 'https://youtu.be/abc'
        )
      end

      it 'logs already_uploaded and exits' do
        allow(StudentVideo).to receive(:find_by).and_return(video)

        expect { job.perform(video_id) }.not_to raise_error

        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[already_uploaded\].*Already uploaded/)
      end
    end

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
          youtube_url: 'https://youtu.be/yt123',
          youtube_id: 'yt123',
          youtube_uploaded_at: kind_of(Time)
        )

        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[success\].*Uploaded to YouTube: yt123/)
      end
    end

    context 'when authorization error occurs' do
      let(:video) do
        instance_double(
          StudentVideo,
          id: video_id,
          approved?: true,
          youtube_url: nil,
          file: double(path: '/tmp/video.mp4'),
          title: 'Test',
          description: 'Test',
          subject_title: 'Test'
        )
      end

      let(:uploader) { instance_double(YoutubeUploadService) }

      before do
        allow(StudentVideo).to receive(:find_by).and_return(video)
        allow(YoutubeUploadService).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:call).and_raise(Signet::AuthorizationError.new('fail'))
      end

      it 'logs auth_error and re-raises' do
        expect { job.perform(video_id) }
          .to raise_error(Signet::AuthorizationError)

        expect(logger).to have_received(:info)
          .with(/\[YouTubeUpload\]\[auth_error\].*Authorization failed/)
      end
    end
  end

  describe 'sidekiq configuration' do
    it 'uses default queue and 5 retries' do
      options = described_class.get_sidekiq_options

      expect(options['queue']).to eq(:default)
      expect(options['retry']).to eq(5)
    end
  end
end
