# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuizResult, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:learning_module) }
  end

  describe 'callbacks' do
    let(:user) { create(:user) }
    let(:school) { user.school }
    let(:subject_model) { create(:subject, school: school) }
    let(:unit) { create(:unit, subject: subject_model) }
    let(:learning_module) { create(:learning_module, unit: unit) }

    describe 'after_create :log_quiz_completion' do
      it 'logs quiz completion event' do
        expect do
          create(:quiz_result, user: user, learning_module: learning_module)
        end.to change(Event, :count).by(1)

        event = Event.last
        expect(event.event_type).to eq('quiz_complete')
        expect(event.user).to eq(user)
        expect(event.data['score']).to eq(85)
        expect(event.data['passed']).to be(true)
      end

      it 'includes quiz result details in event data' do
        quiz_result = create(:quiz_result, user: user, learning_module: learning_module, score: 90, passed: true)

        event = Event.last
        expect(event.data['quiz_result_id']).to eq(quiz_result.id)
        expect(event.data['quiz_id']).to eq(learning_module.id)
        expect(event.data['score']).to eq(90)
        expect(event.data['passed']).to be(true)
      end
    end
  end
end
