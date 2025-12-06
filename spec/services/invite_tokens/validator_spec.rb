# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InviteTokens::Validator do
  describe '.call!' do
    it 'raises ActiveRecord::RecordNotFound for any token' do
      expect do
        described_class.call!('any-token')
      end.to raise_error(ActiveRecord::RecordNotFound, 'Token not found')
    end

    it 'raises ActiveRecord::RecordNotFound for nil token' do
      expect do
        described_class.call!(nil)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises ActiveRecord::RecordNotFound for empty token' do
      expect do
        described_class.call!('')
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
