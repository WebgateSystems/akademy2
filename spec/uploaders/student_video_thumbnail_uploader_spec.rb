# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentVideoThumbnailUploader do
  let(:school) { create(:school) }
  let(:subject_record) { create(:subject, school: school) }
  let(:student) { create(:user, school: school) }
  let(:video) { create(:student_video, user: student, school: school, subject: subject_record) }
  let(:uploader) { described_class.new(video, :thumbnail) }

  describe '#store_dir' do
    it 'returns path with partitioned id' do
      store_dir = uploader.store_dir
      expect(store_dir).to include('uploads/student_videos/thumbnails/')
      expect(store_dir).to include(video.id.to_s)
    end
  end

  describe '#filename' do
    context 'when original_filename is blank' do
      it 'returns nil' do
        allow(uploader).to receive(:original_filename).and_return(nil)
        expect(uploader.filename).to be_nil
      end
    end

    context 'when original_filename is present' do
      before do
        allow(uploader).to receive(:original_filename).and_return('test.jpg')
      end

      it 'generates unique filename with thumb_ prefix' do
        filename = uploader.filename
        expect(filename).to start_with('thumb_')
        expect(filename).to end_with('.jpg')
      end

      it 'preserves extension in lowercase' do
        allow(uploader).to receive(:original_filename).and_return('TEST.PNG')
        expect(uploader.filename).to end_with('.png')
      end
    end
  end

  describe '#extension_allowlist' do
    it 'allows jpg' do
      expect(uploader.extension_allowlist).to include('jpg')
    end

    it 'allows jpeg' do
      expect(uploader.extension_allowlist).to include('jpeg')
    end

    it 'allows png' do
      expect(uploader.extension_allowlist).to include('png')
    end

    it 'allows webp' do
      expect(uploader.extension_allowlist).to include('webp')
    end
  end

  describe '#content_type_allowlist' do
    it 'allows image types' do
      expect(uploader.content_type_allowlist).to eq(%r{image/})
    end
  end

  describe 'storage' do
    it 'uses file storage' do
      expect(uploader.class.storage).to eq(CarrierWave::Storage::File)
    end
  end
end
