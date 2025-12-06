# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::PinForm do
  describe 'validations' do
    context 'with valid 4-digit PIN' do
      let(:form) { described_class.new(pin: '1234') }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    context 'with blank PIN' do
      let(:form) { described_class.new(pin: '') }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:pin]).to include("can't be blank")
      end
    end

    context 'with nil PIN' do
      let(:form) { described_class.new(pin: nil) }

      it 'is invalid' do
        expect(form).not_to be_valid
      end
    end

    context 'with too short PIN' do
      let(:form) { described_class.new(pin: '123') }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:pin]).to include('is the wrong length (should be 4 characters)')
      end
    end

    context 'with too long PIN' do
      let(:form) { described_class.new(pin: '12345') }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:pin]).to include('is the wrong length (should be 4 characters)')
      end
    end
  end
end
