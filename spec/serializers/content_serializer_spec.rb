# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentSerializer, type: :serializer do
  let(:subject_record) { create(:subject, school_id: nil) }
  let(:unit) { create(:unit, subject: subject_record) }
  let(:learning_module) { create(:learning_module, unit: unit, published: true) }

  describe 'attributes' do
    let(:content) do
      create(:content,
             learning_module: learning_module,
             title: 'Test Video',
             content_type: 'video',
             duration_sec: 300,
             youtube_url: 'https://youtube.com/watch?v=test',
             file_hash: 'abc123def456',
             file_format: 'video/mp4')
    end

    let(:serialized) { described_class.new(content).serializable_hash[:data][:attributes] }

    it 'includes id' do
      expect(serialized[:id]).to eq(content.id)
    end

    it 'includes title' do
      expect(serialized[:title]).to eq('Test Video')
    end

    it 'includes content_type' do
      expect(serialized[:content_type]).to eq('video')
    end

    it 'includes file_hash' do
      expect(serialized[:file_hash]).to eq('abc123def456')
    end

    it 'includes file_format' do
      expect(serialized[:file_format]).to eq('video/mp4')
    end

    it 'includes youtube_url' do
      expect(serialized[:youtube_url]).to eq('https://youtube.com/watch?v=test')
    end

    it 'includes duration_sec' do
      expect(serialized[:duration_sec]).to eq(300)
    end
  end

  describe 'when file_hash and file_format are nil' do
    let(:content) do
      create(:content,
             learning_module: learning_module,
             title: 'Test Content',
             content_type: 'video')
    end

    let(:serialized) { described_class.new(content).serializable_hash[:data][:attributes] }

    it 'returns nil for file_hash' do
      expect(serialized[:file_hash]).to be_nil
    end

    it 'returns nil for file_format' do
      expect(serialized[:file_format]).to be_nil
    end
  end
end
