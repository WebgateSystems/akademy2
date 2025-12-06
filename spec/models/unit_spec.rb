# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Unit, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:subject) }
    it { is_expected.to have_many(:learning_modules).dependent(:destroy) }
  end

  describe '#title_with_subject' do
    let(:subject_record) { create(:subject, title: 'Mathematics') }
    let(:unit) { create(:unit, subject: subject_record, title: 'Algebra') }

    it 'returns combined title' do
      expect(unit.title_with_subject).to eq('Mathematics > Algebra')
    end

    context 'when subject is nil' do
      let(:unit) { build(:unit, subject: nil, title: 'Algebra') }

      it 'handles nil subject gracefully' do
        expect(unit.title_with_subject).to eq(' > Algebra')
      end
    end
  end
end
