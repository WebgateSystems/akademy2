# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VideoProcessor do
  let(:video_path) { Rails.root.join('spec/fixtures/test.mp4').to_s }

  describe '#initialize' do
    it 'sets video path' do
      processor = described_class.new(video_path)
      expect(processor.instance_variable_get(:@video_path)).to eq(video_path)
    end

    it 'initializes movie as nil' do
      processor = described_class.new(video_path)
      expect(processor.instance_variable_get(:@movie)).to be_nil
    end
  end

  describe '#process' do
    context 'when ffmpeg is not installed' do
      before do
        allow_any_instance_of(described_class).to receive(:system)
          .with('which ffmpeg > /dev/null 2>&1').and_return(false)
      end

      it 'raises ProcessingError' do
        processor = described_class.new(video_path)
        expect { processor.process }.to raise_error(VideoProcessor::ProcessingError)
      end
    end

    context 'when ffprobe is not installed' do
      before do
        allow_any_instance_of(described_class).to receive(:system)
          .with('which ffmpeg > /dev/null 2>&1').and_return(true)
        allow_any_instance_of(described_class).to receive(:system)
          .with('which ffprobe > /dev/null 2>&1').and_return(false)
      end

      it 'raises ProcessingError' do
        processor = described_class.new(video_path)
        expect { processor.process }.to raise_error(VideoProcessor::ProcessingError)
      end
    end

    context 'when video file does not exist' do
      before do
        allow_any_instance_of(described_class).to receive(:system).and_return(true)
      end

      it 'raises ProcessingError' do
        processor = described_class.new('/non/existent/path.mp4')
        expect { processor.process }.to raise_error(VideoProcessor::ProcessingError)
      end
    end
  end

  describe '#extract_duration' do
    let(:mock_movie) { instance_double(FFMPEG::Movie, duration: 120.5, valid?: true) }

    before do
      allow_any_instance_of(described_class).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).and_return(true)
      allow(FFMPEG::Movie).to receive(:new).and_return(mock_movie)
    end

    it 'returns duration as integer' do
      processor = described_class.new(video_path)
      expect(processor.extract_duration).to eq(120)
    end

    context 'when extraction fails' do
      before do
        allow(mock_movie).to receive(:duration).and_raise(StandardError, 'FFmpeg error')
        allow(Rails.logger).to receive(:error)
      end

      it 'returns 0' do
        processor = described_class.new(video_path)
        expect(processor.extract_duration).to eq(0)
      end

      it 'logs the error' do
        processor = described_class.new(video_path)
        processor.extract_duration
        expect(Rails.logger).to have_received(:error).with(/Failed to extract duration/)
      end
    end
  end

  describe '#generate_thumbnail' do
    let(:mock_movie) do
      instance_double(
        FFMPEG::Movie,
        duration: 120.5,
        width: 1920,
        height: 1080,
        valid?: true
      )
    end

    before do
      allow_any_instance_of(described_class).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).and_call_original
      allow(FFMPEG::Movie).to receive(:new).and_return(mock_movie)
      allow(mock_movie).to receive(:screenshot).and_return(true)
    end

    it 'generates thumbnail with correct resolution' do
      allow(File).to receive(:exist?).with(anything).and_return(true)

      expect(mock_movie).to receive(:screenshot).with(
        anything,
        hash_including(resolution: '640x360')
      )

      processor = described_class.new(video_path)
      processor.generate_thumbnail
    end

    context 'when video is vertical' do
      let(:mock_movie) do
        instance_double(
          FFMPEG::Movie,
          duration: 120.5,
          width: 1080,
          height: 1920,
          valid?: true
        )
      end

      it 'scales by height' do
        allow(File).to receive(:exist?).with(anything).and_return(true)

        expect(mock_movie).to receive(:screenshot).with(
          anything,
          hash_including(resolution: '360x640')
        )

        processor = described_class.new(video_path)
        processor.generate_thumbnail
      end
    end

    context 'when generation fails' do
      before do
        allow(mock_movie).to receive(:screenshot).and_raise(StandardError, 'Screenshot error')
        allow(Rails.logger).to receive(:error)
      end

      it 'returns nil' do
        processor = described_class.new(video_path)
        expect(processor.generate_thumbnail).to be_nil
      end

      it 'logs the error' do
        processor = described_class.new(video_path)
        processor.generate_thumbnail
        expect(Rails.logger).to have_received(:error).with(/Failed to generate thumbnail/)
      end
    end
  end

  describe '#metadata' do
    let(:mock_movie) do
      instance_double(
        FFMPEG::Movie,
        duration: 120.5,
        bitrate: 5000,
        size: 1_000_000,
        video_codec: 'h264',
        audio_codec: 'aac',
        resolution: '1920x1080',
        width: 1920,
        height: 1080,
        frame_rate: 30.0,
        valid?: true
      )
    end

    before do
      allow_any_instance_of(described_class).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).and_return(true)
      allow(FFMPEG::Movie).to receive(:new).and_return(mock_movie)
    end

    it 'returns video metadata hash' do
      processor = described_class.new(video_path)
      metadata = processor.metadata

      expect(metadata).to include(
        duration: 120.5,
        bitrate: 5000,
        video_codec: 'h264',
        audio_codec: 'aac',
        resolution: '1920x1080',
        width: 1920,
        height: 1080,
        frame_rate: 30.0
      )
    end

    context 'when metadata extraction fails' do
      before do
        allow(mock_movie).to receive(:duration).and_raise(StandardError, 'Metadata error')
        allow(Rails.logger).to receive(:error)
      end

      it 'returns empty hash' do
        processor = described_class.new(video_path)
        expect(processor.metadata).to eq({})
      end

      it 'logs the error' do
        processor = described_class.new(video_path)
        processor.metadata
        expect(Rails.logger).to have_received(:error).with(/Failed to get metadata/)
      end
    end
  end

  describe 'constants' do
    it 'has THUMBNAIL_TIME constant' do
      expect(described_class::THUMBNAIL_TIME).to eq(1)
    end

    it 'has THUMBNAIL_MAX_DIMENSION constant' do
      expect(described_class::THUMBNAIL_MAX_DIMENSION).to eq(640)
    end
  end

  describe 'ProcessingError' do
    it 'is a StandardError' do
      expect(VideoProcessor::ProcessingError.ancestors).to include(StandardError)
    end
  end
end
