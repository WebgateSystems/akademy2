RSpec.describe Content, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:learning_module) }
  end

  describe 'columns' do
    it { is_expected.to have_db_column(:content_type) }
    it { is_expected.to have_db_column(:duration_sec) }
    it { is_expected.to have_db_column(:file) }
    it { is_expected.to have_db_column(:learning_module_id) }
    it { is_expected.to have_db_column(:order_index) }
    it { is_expected.to have_db_column(:payload) }
    it { is_expected.to have_db_column(:poster) }
    it { is_expected.to have_db_column(:subtitles) }
    it { is_expected.to have_db_column(:title) }
  end
end
