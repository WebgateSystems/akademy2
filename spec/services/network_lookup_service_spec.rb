# spec/services/network_lookup_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'
require 'net/http'

RSpec.describe NetworkLookupService do
  subject(:service) { described_class.new(ip) }

  let(:ip) { '8.8.8.8' }

  let(:http) { instance_double(Net::HTTP) }
  let(:response) { Net::HTTPSuccess.new('1.1', '200', 'OK') }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(response).to receive(:body).and_return(response_body)
    allow(http).to receive(:request).and_return(response)
  end

  describe '#cidrs' do
    context 'when RDAP returns cidr0_cidrs (IPv4)' do
      let(:response_body) do
        {
          cidr0_cidrs: [
            { v4prefix: '8.8.8.0', length: 24 }
          ]
        }.to_json
      end

      it 'returns CIDR from cidr0_cidrs' do
        expect(service.cidrs).to eq(['8.8.8.0/24'])
      end
    end

    context 'when RDAP returns cidr0_cidrs (IPv6)' do
      let(:response_body) do
        {
          cidr0_cidrs: [
            { v6prefix: '2001:4860::', length: 32 }
          ]
        }.to_json
      end

      it 'returns IPv6 CIDR' do
        expect(service.cidrs).to eq(['2001:4860::/32'])
      end
    end

    context 'when cidr0_cidrs is empty but range exists' do
      let(:response_body) do
        {
          startAddress: '192.168.0.0',
          endAddress: '192.168.0.255'
        }.to_json
      end

      it 'calculates CIDRs from range' do
        expect(service.cidrs).to eq(['192.168.0.0/24'])
      end
    end

    context 'when range produces minimal single CIDR' do
      let(:response_body) do
        {
          startAddress: '192.168.0.0',
          endAddress: '192.168.1.255'
        }.to_json
      end

      it 'returns minimal covering CIDR' do
        expect(service.cidrs).to eq(['192.168.0.0/23'])
      end
    end

    context 'when RDAP returns invalid JSON structure' do
      let(:response_body) { '"invalid"' }

      it 'returns empty array' do
        expect(service.cidrs).to eq([])
      end
    end

    context 'when HTTP raises an error' do
      before do
        allow(http).to receive(:request).and_raise(StandardError)
      end

      let(:response_body) { '{}' }

      it 'returns empty array' do
        expect(service.cidrs).to eq([])
      end
    end

    context 'when range contains invalid IPs' do
      let(:response_body) do
        {
          startAddress: 'bad-ip',
          endAddress: '192.168.0.1'
        }.to_json
      end

      it 'returns empty array' do
        expect(service.cidrs).to eq([])
      end
    end
  end
end
