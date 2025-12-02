# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Subjects interactors' do
  let(:user) { create(:user) }
  let(:subject_record) { create(:subject, school: nil) }

  before do
    unit = Unit.create!(subject: subject_record, title: 'Unit', order_index: 0)
    LearningModule.create!(unit: unit, title: 'Module', order_index: 0, published: true)
  end

  describe Api::V1::Subjects::ListSubjects do
    it 'returns global subjects for authenticated users' do
      result = described_class.call(current_user: user, params: {})

      expect(result).to be_success
      expect(result.form).to include(subject_record)
      expect(result.serializer).to eq(SubjectSerializer)
    end
  end

  describe Api::V1::Subjects::ListSubjectsWithContents do
    it 'returns nested subject structure' do
      result = described_class.call(current_user: user, params: {})

      expect(result).to be_success
      expect(result.form.first.units.first.learning_modules.first).to be_published
      expect(result.serializer).to eq(SubjectCompleteSerializer)
      expect(result.params[:current_user]).to eq(user)
    end
  end

  describe Api::V1::Subjects::ShowSubject do
    it 'returns a single subject with nested associations' do
      result = described_class.call(current_user: user, params: { id: subject_record.id })

      expect(result).to be_success
      expect(result.form).to eq(subject_record)
    end

    it 'fails when subject is missing' do
      result = described_class.call(current_user: user, params: { id: SecureRandom.uuid })

      expect(result).to be_failure
      expect(result.status).to eq(:not_found)
    end
  end
end
