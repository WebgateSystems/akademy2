# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::VerifyPhoneForm do
  describe 'validations' do
    context 'with valid 4-digit code' do
      let(:form) { described_class.new(code: '1234') }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    context 'with blank code' do
      let(:form) { described_class.new(code: '') }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:code]).to include("can't be blank")
      end
    end

    context 'with nil code' do
      let(:form) { described_class.new(code: nil) }

      it 'is invalid' do
        expect(form).not_to be_valid
      end
    end

    context 'with too short code' do
      let(:form) { described_class.new(code: '123') }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:code]).to include('is the wrong length (should be 4 characters)')
      end
    end

    context 'with too long code' do
      let(:form) { described_class.new(code: '12345') }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:code]).to include('is the wrong length (should be 4 characters)')
      end
    end
  end
end
