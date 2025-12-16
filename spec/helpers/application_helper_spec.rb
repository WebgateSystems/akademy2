# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#app_version' do
    it 'returns app version string' do
      allow(AppIdService).to receive(:version).and_return('1.2.3')
      expect(helper.app_version).to eq('App version: #1.2.3')
    end
  end

  describe '#render_qr_svg' do
    let(:test_url) { 'https://akademy.edu.pl/certificates/test-123' }

    it 'returns SVG content' do
      result = helper.render_qr_svg(test_url)

      expect(result).to include('<svg')
      expect(result).to include('</svg>')
    end

    it 'sets width and height based on size parameter' do
      result = helper.render_qr_svg(test_url, size: 200)

      expect(result).to include('width="200"')
      expect(result).to include('height="200"')
    end

    it 'uses default size of 150' do
      result = helper.render_qr_svg(test_url)

      expect(result).to include('width="150"')
      expect(result).to include('height="150"')
    end

    it 'returns html_safe string' do
      result = helper.render_qr_svg(test_url)

      expect(result).to be_html_safe
    end

    it 'generates valid QR code for URL' do
      result = helper.render_qr_svg(test_url)

      # SVG should contain path elements for QR code
      expect(result).to include('<path')
    end

    it 'accepts custom colors' do
      result = helper.render_qr_svg(test_url, dark_color: 'FF0000', light_color: 'FFFFFF')

      # Should generate valid SVG
      expect(result).to include('<svg')
    end
  end
end
