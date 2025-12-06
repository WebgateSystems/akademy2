# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppIdService do
  describe '#version' do
    before do
      # Reset cached version before each test
      described_class.instance_variable_set(:@version, nil)
    end

    after do
      # Reset cached version after each test to avoid polluting other tests
      described_class.instance_variable_set(:@version, nil)
    end

    context 'when we use capistrano' do
      let(:hash) { SecureRandom.hex }

      before do
        File.write('REVISION', hash)
      end

      after do
        File.delete('REVISION') if File.exist?('REVISION')
      end

      it 'is equal the hash in REVISION file' do
        expect(described_class.version).to eq(hash.first(8))
      end
    end

    context 'when REVISION file does not exist' do
      before do
        File.delete('REVISION') if File.exist?('REVISION')
      end

      it 'returns git short hash' do
        expect(described_class.version).to match(/\A[a-f0-9]{7,8}\z/)
      end
    end
  end
end
