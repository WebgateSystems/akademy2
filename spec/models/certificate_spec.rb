require 'rails_helper'

RSpec.describe Certificate, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:quiz_result) }
  end

  describe 'columns' do
    it { is_expected.to have_db_column(:certificate_number) }
    it { is_expected.to have_db_column(:pdf) }
    it { is_expected.to have_db_column(:issued_at) }
    it { is_expected.to have_db_column(:quiz_result_id) }
  end
end
