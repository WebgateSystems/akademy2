# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseInteractor do
  let(:dummy_class) do
    Class.new(described_class) do
      attr_writer :current_form

      def call; end

      attr_reader :current_form
    end
  end

  let(:interactor) do
    instance = dummy_class.new
    instance.instance_variable_set(:@context, Interactor::Context.build)
    instance
  end

  describe '#access_denied' do
    it 'marks context as forbidden' do
      expect { interactor.send(:access_denied) }.to raise_error(Interactor::Failure)
      expect(interactor.context.message).to eq(['Access Denied'])
      expect(interactor.context.status).to eq(:forbidden)
    end
  end

  describe '#not_found' do
    it 'marks context as not found' do
      expect { interactor.send(:not_found) }.to raise_error(Interactor::Failure)
      expect(interactor.context.message).to eq(['Not Found'])
      expect(interactor.context.status).to eq(:not_found)
    end
  end

  describe '#no_content' do
    it 'sets status to no_content' do
      expect { interactor.send(:no_content) }.to raise_error(Interactor::Failure)
      expect(interactor.context.status).to eq(:no_content)
    end
  end

  describe '#bad_outcome' do
    it 'copies errors from current_form' do
      form = double('Form', errors: { email: ['invalid'] }, messages: ['invalid data'])
      interactor.instance_variable_set(:@current_form, form)

      expect { interactor.send(:bad_outcome) }.to raise_error(Interactor::Failure)
      expect(interactor.context.errors).to eq(email: ['invalid'])
      expect(interactor.context.message).to eq(['invalid data'])
    end
  end

  describe '#bad_result' do
    it 'copies message and status from provided form' do
      form = double('Result', message: ['failed'], status: :unprocessable_entity)

      expect { interactor.send(:bad_result, form) }.to raise_error(Interactor::Failure)
      expect(interactor.context.message).to eq(['failed'])
      expect(interactor.context.status).to eq(:unprocessable_entity)
    end
  end
end
