# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubjectCompleteSerializer, type: :serializer do
  let(:subject_record) { create(:subject, title: 'Test Subject', school_id: nil, order_index: 1) }
  let(:unit) { create(:unit, subject: subject_record, title: 'Test Unit', order_index: 1) }
  let(:learning_module) do
    create(:learning_module, unit: unit, title: 'Test Module', order_index: 1, published: true)
  end

  describe 'contents with file metadata' do
    let(:content_with_file) do
      create(:content,
             learning_module: learning_module,
             title: 'Video with file',
             content_type: 'video',
             order_index: 1,
             file_hash: 'sha256hashvalue123',
             file_format: 'video/mp4')
    end

    let(:content_without_file) do
      create(:content,
             learning_module: learning_module,
             title: 'YouTube video',
             content_type: 'video',
             order_index: 2,
             youtube_url: 'https://youtube.com/watch?v=test')
    end

    let(:serialized) do
      content_with_file
      content_without_file
      described_class.new(subject_record).serializable_hash[:data][:attributes]
    end
    let(:serialized_contents) { serialized[:unit][:learning_module][:contents] }

    it 'includes file_hash for content with uploaded file' do
      content_data = serialized_contents.find { |c| c[:title] == 'Video with file' }
      expect(content_data[:file_hash]).to eq('sha256hashvalue123')
    end

    it 'includes file_format for content with uploaded file' do
      content_data = serialized_contents.find { |c| c[:title] == 'Video with file' }
      expect(content_data[:file_format]).to eq('video/mp4')
    end

    it 'returns nil file_hash for content without file' do
      content_data = serialized_contents.find { |c| c[:title] == 'YouTube video' }
      expect(content_data[:file_hash]).to be_nil
    end

    it 'returns nil file_format for content without file' do
      content_data = serialized_contents.find { |c| c[:title] == 'YouTube video' }
      expect(content_data[:file_format]).to be_nil
    end

    it 'includes all expected content keys' do
      content_data = serialized_contents.first
      expect(content_data.keys).to include(
        :id, :title, :content_type, :order_index, :duration_sec,
        :youtube_url, :payload, :file_url, :file_hash, :file_format,
        :poster_url, :subtitles_url
      )
    end
  end

  describe 'when learning module is unpublished' do
    let(:unpublished_module) do
      create(:learning_module, unit: unit, title: 'Unpublished Module', published: false)
    end

    let(:content) do
      create(:content,
             learning_module: unpublished_module,
             title: 'Hidden Content',
             content_type: 'video')
    end

    context 'without admin user' do
      let(:serialized) do
        content # ensure content exists
        described_class.new(subject_record).serializable_hash[:data][:attributes]
      end

      it 'does not include unpublished module contents' do
        # The serializer should return nil for unpublished modules for non-admin users
        expect(serialized[:unit]).to be_nil
      end
    end

    context 'with admin user' do
      let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
      let(:admin_user) do
        user = create(:user)
        UserRole.create!(user: user, role: admin_role, school: user.school)
        user
      end

      let(:serialized) do
        content # ensure content exists
        described_class.new(subject_record, params: { current_user: admin_user }).serializable_hash[:data][:attributes]
      end

      it 'includes unpublished module contents for admin' do
        expect(serialized[:unit]).to be_present
        expect(serialized[:unit][:learning_module]).to be_present
      end
    end
  end
end
