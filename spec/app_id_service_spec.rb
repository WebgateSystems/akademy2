# frozen_string_literal: true

RSpec.describe AppIdService do
  describe '#version' do
    context 'when we use capistrano' do
      let(:hash) { SecureRandom.hex }

      before do
        File.write('REVISION', hash)
      end

      after do
        File.delete('REVISION')
      end

      it 'is equal the hash in REVISION file' do
        expect(described_class.version).to eq(hash.first(8))
      end
    end
  end
end
