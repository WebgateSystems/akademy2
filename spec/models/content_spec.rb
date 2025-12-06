RSpec.describe Content, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:learning_module) }
    it { is_expected.to have_many(:likes).class_name('ContentLike').dependent(:destroy) }
    it { is_expected.to have_many(:liking_users).through(:likes).source(:user) }
  end

  describe '#likeable?' do
    let(:subject_record) { create(:subject, school_id: nil) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit) }

    it 'returns true for video content' do
      content = create(:content, learning_module: learning_module, content_type: 'video')
      expect(content.likeable?).to be true
    end

    it 'returns true for infographic content' do
      content = create(:content, learning_module: learning_module, content_type: 'infographic')
      expect(content.likeable?).to be true
    end

    it 'returns false for quiz content' do
      content = create(:content, learning_module: learning_module, content_type: 'quiz')
      expect(content.likeable?).to be false
    end
  end

  describe '#liked_by?' do
    let(:user) { create(:user) }
    let(:subject_record) { create(:subject, school_id: nil) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit) }
    let(:content) { create(:content, learning_module: learning_module, content_type: 'video') }

    it 'returns false when user is nil' do
      expect(content.liked_by?(nil)).to be false
    end

    it 'returns false when user has not liked' do
      expect(content.liked_by?(user)).to be false
    end

    it 'returns true when user has liked' do
      ContentLike.create!(content: content, user: user)
      expect(content.liked_by?(user)).to be true
    end
  end

  describe '#toggle_like!' do
    let(:user) { create(:user) }
    let(:subject_record) { create(:subject, school_id: nil) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit) }

    context 'when content is likeable' do
      let(:content) { create(:content, learning_module: learning_module, content_type: 'video') }

      it 'creates like when not already liked' do
        expect { content.toggle_like!(user) }.to change(ContentLike, :count).by(1)
        expect(content.toggle_like!(user)).to be false # Second call removes like
      end

      it 'removes like when already liked' do
        ContentLike.create!(content: content, user: user)
        expect { content.toggle_like!(user) }.to change(ContentLike, :count).by(-1)
      end

      it 'returns true when creating like' do
        expect(content.toggle_like!(user)).to be true
      end

      it 'returns false when removing like' do
        ContentLike.create!(content: content, user: user)
        expect(content.toggle_like!(user)).to be false
      end
    end

    context 'when content is not likeable' do
      let(:content) { create(:content, learning_module: learning_module, content_type: 'quiz') }

      it 'returns false' do
        expect(content.toggle_like!(user)).to be false
      end

      it 'does not create like' do
        expect { content.toggle_like!(user) }.not_to change(ContentLike, :count)
      end
    end
  end

  describe 'columns' do
    it { is_expected.to have_db_column(:content_type) }
    it { is_expected.to have_db_column(:duration_sec) }
    it { is_expected.to have_db_column(:file) }
    it { is_expected.to have_db_column(:file_hash) }
    it { is_expected.to have_db_column(:file_format) }
    it { is_expected.to have_db_column(:learning_module_id) }
    it { is_expected.to have_db_column(:order_index) }
    it { is_expected.to have_db_column(:payload) }
    it { is_expected.to have_db_column(:poster) }
    it { is_expected.to have_db_column(:subtitles) }
    it { is_expected.to have_db_column(:title) }
  end

  describe 'file metadata generation' do
    let(:subject_record) { create(:subject, school_id: nil) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit) }

    describe '#update_file_hash' do
      context 'when file is uploaded' do
        let(:content) do
          content = build(:content, learning_module: learning_module)
          # Create a temp file with known content for predictable hash
          temp_file = Tempfile.new(['test_video', '.mp4'])
          temp_file.write('test video content for hash generation')
          temp_file.rewind
          content.file = temp_file
          content.save!
          temp_file.close
          content
        end

        it 'generates SHA256 hash for uploaded file' do
          expect(content.file_hash).to be_present
          expect(content.file_hash).to match(/\A[a-f0-9]{64}\z/)
        end
      end

      context 'when no file is uploaded' do
        let(:content) { create(:content, learning_module: learning_module) }

        it 'does not set file_hash' do
          expect(content.file_hash).to be_nil
        end
      end
    end

    describe '#update_file_format' do
      context 'when mp4 file is uploaded' do
        let(:content) do
          content = build(:content, learning_module: learning_module)
          temp_file = Tempfile.new(['test_video', '.mp4'])
          temp_file.write('fake mp4 content')
          temp_file.rewind
          content.file = temp_file
          content.save!
          temp_file.close
          content
        end

        it 'detects video/mp4 format' do
          expect(content.file_format).to eq('video/mp4')
        end
      end

      context 'when webm file is uploaded' do
        let(:content) do
          content = build(:content, learning_module: learning_module)
          temp_file = Tempfile.new(['test_video', '.webm'])
          temp_file.write('fake webm content')
          temp_file.rewind
          content.file = temp_file
          content.save!
          temp_file.close
          content
        end

        it 'detects video/webm format' do
          expect(content.file_format).to eq('video/webm')
        end
      end

      context 'when no file is uploaded' do
        let(:content) { create(:content, learning_module: learning_module) }

        it 'does not set file_format' do
          expect(content.file_format).to be_nil
        end
      end
    end

    describe 'VIDEO_FORMATS constant' do
      it 'defines supported video formats' do
        expect(Content::VIDEO_FORMATS).to include(
          'mp4' => 'video/mp4',
          'webm' => 'video/webm',
          'mov' => 'video/quicktime'
        )
      end
    end

    describe 'MIME_TYPES constant' do
      it 'defines supported non-video MIME types' do
        expect(Content::MIME_TYPES).to include(
          'pdf' => 'application/pdf',
          'jpg' => 'image/jpeg',
          'png' => 'image/png'
        )
      end
    end
  end
end
