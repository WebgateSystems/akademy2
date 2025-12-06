# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Register::ProfileForm do
  describe 'validations' do
    let(:valid_attrs) do
      {
        first_name: 'John',
        last_name: 'Doe',
        birthdate: '1990-01-15',
        email: 'john@example.com',
        phone: '+48123456789'
      }
    end

    context 'with valid attributes' do
      let(:form) { described_class.new(valid_attrs) }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    context 'without first_name' do
      let(:form) { described_class.new(valid_attrs.merge(first_name: '')) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:first_name]).to include("can't be blank")
      end
    end

    context 'without last_name' do
      let(:form) { described_class.new(valid_attrs.merge(last_name: '')) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:last_name]).to include("can't be blank")
      end
    end

    context 'without email' do
      let(:form) { described_class.new(valid_attrs.merge(email: '')) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:email]).to include("can't be blank")
      end
    end

    context 'with invalid email format' do
      let(:form) { described_class.new(valid_attrs.merge(email: 'invalid')) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:email]).to include('is not valid')
      end
    end

    context 'without phone' do
      let(:form) { described_class.new(valid_attrs.merge(phone: '')) }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:phone]).to include("can't be blank")
      end
    end
  end

  describe '#to_h' do
    let(:form) do
      described_class.new(
        first_name: 'John',
        last_name: 'Doe',
        birthdate: '1990-01-15',
        email: 'john@example.com',
        phone: '+48123456789'
      )
    end

    it 'returns hash with all attributes' do
      expect(form.to_h).to eq({
                                'first_name' => 'John',
                                'last_name' => 'Doe',
                                'birthdate' => '1990-01-15',
                                'email' => 'john@example.com',
                                'phone' => '+48123456789'
                              })
    end
  end
end
