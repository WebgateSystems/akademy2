# spec/services/admin/event_block_rule_builder_spec.rb
require 'rails_helper'

RSpec.describe Admin::EventBlockRuleBuilder do
  let(:user_id) { 123 }
  let(:ip) { '192.168.1.42' }

  let(:event_with_user_and_ip) do
    OpenStruct.new(id: 1, user_id: user_id, data: { 'ip' => ip })
  end

  let(:event_without_user) { OpenStruct.new(id: 2, user_id: nil, data: { 'ip' => ip }) }
  let(:event_without_ip) { OpenStruct.new(id: 3, user_id: user_id, data: {}) }

  describe '#call' do
    context 'when kind is user' do
      it 'builds a rule with user_id' do
        builder = described_class.new(event: event_with_user_and_ip, kind: :user, params: {})
        expect(builder.call).to eq(
          rule_type: 'user',
          value: user_id,
          note: "Blocked user from Event##{event_with_user_and_ip.id}"
        )
      end

      it 'returns error if user_id is missing' do
        builder = described_class.new(event: event_without_user, kind: :user, params: {})
        expect(builder.call).to eq(
          error: 'Ten event nie ma user_id — nie można zablokować użytkownika.'
        )
      end
    end

    context 'when kind is ip' do
      it 'builds a rule with event ip' do
        builder = described_class.new(event: event_with_user_and_ip, kind: :ip, params: {})
        expect(builder.call).to eq(
          rule_type: 'ip',
          value: ip,
          note: "Blocked from Event##{event_with_user_and_ip.id}"
        )
      end

      it 'returns error if ip is missing' do
        builder = described_class.new(event: event_without_ip, kind: :ip, params: {})
        expect(builder.call).to eq(
          error: 'Ten event nie ma IP — nie można zablokować IP.'
        )
      end
    end

    context 'when kind is network' do
      let(:network_override) { '192.168.1.0/24' }

      it 'builds network rule using override if provided' do
        builder = described_class.new(
          event: event_with_user_and_ip,
          kind: :network,
          params: { value: network_override }
        )

        expect(builder.call).to eq(
          rule_type: 'cidr',
          value: network_override,
          ip: ip,
          resolution: 'confirmed',
          note: "Blocked network (confirmed) from Event##{event_with_user_and_ip.id} ip=#{ip}"
        )
      end

      it 'returns error if override CIDR is invalid' do
        builder = described_class.new(
          event: event_with_user_and_ip,
          kind: :network,
          params: { value: 'invalid_cidr' }
        )

        expect(builder.call).to eq(
          error: 'Nieprawidłowy CIDR.'
        )
      end

      it 'returns error if override does not include event IP' do
        builder = described_class.new(
          event: event_with_user_and_ip,
          kind: :network,
          params: { value: '10.0.0.0/8' }
        )

        expect(builder.call).to eq(
          error: 'CIDR nie obejmuje IP eventu.'
        )
      end

      it 'builds network rule from RDAP if no override' do
        fake_service = instance_double(NetworkLookupService, cidrs: ['192.168.1.0/24', '192.168.1.0/25'])
        allow(NetworkLookupService).to receive(:new).with(ip).and_return(fake_service)

        builder = described_class.new(event: event_with_user_and_ip, kind: :network, params: {})
        result = builder.call

        expect(result[:rule_type]).to eq('cidr')
        expect(result[:value]).to eq('192.168.1.0/25') # most specific
        expect(result[:ip]).to eq(ip)
        expect(result[:resolution]).to eq('rdap')
        expect(result[:note]).to include("Blocked network (rdap) from Event##{event_with_user_and_ip.id}")
      end

      it 'falls back to /24 for IPv4 if RDAP fails' do
        fake_service = instance_double(NetworkLookupService, cidrs: [])
        allow(NetworkLookupService).to receive(:new).with(ip).and_return(fake_service)

        builder = described_class.new(event: event_with_user_and_ip, kind: :network, params: {})
        result = builder.call

        expect(result[:rule_type]).to eq('cidr')
        expect(result[:value]).to eq('192.168.1.0/24')
        expect(result[:ip]).to eq(ip)
        expect(result[:resolution]).to eq('fallback')
      end

      it 'returns error if IP is missing' do
        builder = described_class.new(event: event_without_ip, kind: :network, params: {})
        expect(builder.call).to eq(
          error: 'Ten event nie ma IP — nie można zablokować sieci.'
        )
      end
    end

    context 'when kind is unknown' do
      it 'returns nil' do
        builder = described_class.new(event: event_with_user_and_ip, kind: :unknown, params: {})
        expect(builder.call).to be_nil
      end
    end
  end
end
