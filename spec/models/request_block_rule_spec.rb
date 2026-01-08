# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestBlockRule, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:rule_type) }
    it { is_expected.to validate_inclusion_of(:rule_type).in_array(%w[ip cidr user]) }
    it { is_expected.to validate_presence_of(:value) }
  end

  describe '.blocked?' do
    let!(:ip_rule) { create(:request_block_rule, rule_type: 'ip', value: '1.2.3.4') }
    let!(:user_rule) { create(:request_block_rule, rule_type: 'user', value: '42') }

    it 'returns true if IP is blocked' do
      expect(described_class.blocked?(ip: '1.2.3.4')).to be true
    end

    it 'returns true if User ID is blocked' do
      expect(described_class.blocked?(user_id: 42)).to be true
    end

    it 'returns false if nothing matches' do
      expect(described_class.blocked?(ip: '8.8.8.8', user_id: 99)).to be false
    end

    it 'ignores disabled rules' do
      ip_rule.update!(enabled: false)
      expect(described_class.blocked?(ip: '1.2.3.4')).to be false
    end
  end

  describe '#matches?' do
    context 'with IP rule' do
      subject(:rule) { build(:request_block_rule, rule_type: 'ip', value: '192.168.1.1') }

      it 'matches exact IP' do
        expect(rule.matches?(ip: '192.168.1.1')).to be true
      end

      it 'does not match different IP' do
        expect(rule.matches?(ip: '192.168.1.2')).to be false
      end
    end

    context 'with CIDR rule' do
      subject(:rule) { build(:request_block_rule, rule_type: 'cidr', value: '10.0.0.0/24') }

      it 'matches IP within range' do
        expect(rule.matches?(ip: '10.0.0.50')).to be true
      end

      it 'matches boundary IP' do
        expect(rule.matches?(ip: '10.0.0.255')).to be true
      end

      it 'does not match IP outside range' do
        expect(rule.matches?(ip: '10.0.1.1')).to be false
      end

      it 'handles invalid CIDR gracefully' do
        rule.value = 'invalid_range'
        expect(rule.matches?(ip: '10.0.0.1')).to be false
      end
    end

    context 'with User rule' do
      subject(:rule) { build(:request_block_rule, rule_type: 'user', value: '123') }

      it 'matches exact user_id as string' do
        expect(rule.matches?(ip: nil, user_id: '123')).to be true
      end

      it 'matches user_id as integer' do
        expect(rule.matches?(ip: nil, user_id: 123)).to be true
      end

      it 'does not match different user_id' do
        expect(rule.matches?(ip: nil, user_id: 456)).to be false
      end
    end
  end
end
