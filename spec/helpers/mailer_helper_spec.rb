# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MailerHelper, type: :helper do
  describe '#embedded_logo_data_uri' do
    context 'when logo file exists' do
      it 'returns a data URI string' do
        result = helper.embedded_logo_data_uri
        expect(result).to start_with('data:image/svg+xml;base64,')
      end

      it 'contains valid base64 encoded content' do
        result = helper.embedded_logo_data_uri
        base64_content = result.sub('data:image/svg+xml;base64,', '')

        expect { Base64.strict_decode64(base64_content) }.not_to raise_error
      end

      it 'decodes to valid SVG content' do
        result = helper.embedded_logo_data_uri
        base64_content = result.sub('data:image/svg+xml;base64,', '')
        decoded = Base64.strict_decode64(base64_content)

        expect(decoded).to include('<svg')
        expect(decoded).to include('</svg>')
      end
    end

    context 'when logo file does not exist' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'returns empty string' do
        expect(helper.embedded_logo_data_uri).to eq('')
      end
    end
  end
end
