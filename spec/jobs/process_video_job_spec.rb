# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProcessVideoJob, type: :job do
  describe '#perform' do
    context 'when video does not exist' do
      it 'returns early without error' do
        expect { described_class.new.perform('nonexistent-id') }.not_to raise_error
      end
    end

    context 'when video file is blank' do
      it 'returns early without error' do
        video_double = instance_double(StudentVideo, id: 'test-id')
        file_double = double(blank?: true)
        allow(video_double).to receive(:file).and_return(file_double)
        allow(StudentVideo).to receive(:find_by).with(id: 'test-id').and_return(video_double)

        expect { described_class.new.perform('test-id') }.not_to raise_error
      end
    end

    context 'when video file path does not exist' do
      it 'returns early without error' do
        video_double = instance_double(StudentVideo, id: 'test-id')
        file_double = double(blank?: false, path: '/non/existent/path.mp4')
        allow(video_double).to receive(:file).and_return(file_double)
        allow(StudentVideo).to receive(:find_by).with(id: 'test-id').and_return(video_double)

        expect { described_class.new.perform('test-id') }.not_to raise_error
      end
    end

    context 'when video processing succeeds' do
      let(:video_double) do
        instance_double(
          StudentVideo,
          id: 'test-id',
          thumbnail: nil
        )
      end

      let(:file_double) { double(blank?: false, path: '/tmp/test.mp4') }

      let(:processor_double) do
        instance_double(VideoProcessor, process: { duration_sec: 120, thumbnail_path: nil })
      end

      before do
        allow(video_double).to receive(:file).and_return(file_double)
        allow(StudentVideo).to receive(:find_by).with(id: 'test-id').and_return(video_double)
        allow(File).to receive(:exist?).with('/tmp/test.mp4').and_return(true)
        allow(VideoProcessor).to receive(:new).and_return(processor_double)
        allow(video_double).to receive(:update_column)
        allow(Rails.logger).to receive(:info)
      end

      it 'updates video duration' do
        expect(video_double).to receive(:update_column).with(:duration_sec, 120)
        described_class.new.perform('test-id')
      end

      it 'logs success message' do
        expect(Rails.logger).to receive(:info).with(/Processed video test-id/)
        described_class.new.perform('test-id')
      end
    end

    context 'when video processing generates thumbnail' do
      let(:video_double) do
        instance_double(
          StudentVideo,
          id: 'test-id'
        )
      end

      let(:file_double) { double(blank?: false, path: '/tmp/test.mp4') }
      let(:thumbnail_path) { Rails.root.join('tmp/test_thumb.jpg').to_s }

      let(:processor_double) do
        instance_double(VideoProcessor, process: { duration_sec: 120, thumbnail_path: thumbnail_path })
      end

      before do
        allow(video_double).to receive_messages(file: file_double, thumbnail: nil)
        allow(video_double).to receive(:thumbnail=)
        allow(video_double).to receive(:save!)
        allow(video_double).to receive(:update_column)
        allow(StudentVideo).to receive(:find_by).with(id: 'test-id').and_return(video_double)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('/tmp/test.mp4').and_return(true)
        allow(VideoProcessor).to receive(:new).and_return(processor_double)
        allow(Rails.logger).to receive(:info)
        allow(FileUtils).to receive(:rm_f)

        # Create a temp file for the test
        FileUtils.mkdir_p(File.dirname(thumbnail_path))
        File.write(thumbnail_path, 'test thumbnail content')
      end

      after do
        FileUtils.rm_f(thumbnail_path)
      end

      it 'attaches thumbnail to video' do
        expect(video_double).to receive(:thumbnail=)
        expect(video_double).to receive(:save!)
        described_class.new.perform('test-id')
      end

      it 'cleans up temp file' do
        expect(FileUtils).to receive(:rm_f).with(thumbnail_path)
        described_class.new.perform('test-id')
      end
    end

    context 'when VideoProcessor raises ProcessingError' do
      let(:video_double) { instance_double(StudentVideo, id: 'test-id') }
      let(:file_double) { double(blank?: false, path: '/tmp/test.mp4') }

      before do
        allow(video_double).to receive(:file).and_return(file_double)
        allow(StudentVideo).to receive(:find_by).with(id: 'test-id').and_return(video_double)
        allow(File).to receive(:exist?).with('/tmp/test.mp4').and_return(true)
        allow(VideoProcessor).to receive(:new).and_raise(VideoProcessor::ProcessingError, 'FFmpeg error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error and does not raise' do
        expect(Rails.logger).to receive(:error).with(/Processing error/)
        expect { described_class.new.perform('test-id') }.not_to raise_error
      end
    end

    context 'when unexpected error occurs' do
      let(:video_double) { instance_double(StudentVideo, id: 'test-id') }
      let(:file_double) { double(blank?: false, path: '/tmp/test.mp4') }

      before do
        allow(video_double).to receive(:file).and_return(file_double)
        allow(StudentVideo).to receive(:find_by).with(id: 'test-id').and_return(video_double)
        allow(File).to receive(:exist?).with('/tmp/test.mp4').and_return(true)
        allow(VideoProcessor).to receive(:new).and_raise(StandardError, 'Unexpected error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error and re-raises' do
        expect(Rails.logger).to receive(:error).with(/Unexpected error/)
        expect { described_class.new.perform('test-id') }.to raise_error(StandardError, 'Unexpected error')
      end
    end
  end

  describe 'queue' do
    it 'uses default queue' do
      expect(described_class.sidekiq_options['queue']).to eq(:default)
    end
  end
end
