# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#app_version' do
    it 'returns app version string' do
      allow(AppIdService).to receive(:version).and_return('1.2.3')
      expect(helper.app_version).to eq('App version: #1.2.3')
    end
  end
end
