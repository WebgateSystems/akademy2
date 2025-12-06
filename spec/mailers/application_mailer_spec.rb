# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  describe 'default settings' do
    it 'has default from address' do
      expect(described_class.default[:from]).to eq('from@example.com')
    end
  end

  describe 'layout' do
    it 'uses mailer layout' do
      expect(described_class._layout).to eq('mailer')
    end
  end
end
