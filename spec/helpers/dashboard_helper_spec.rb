# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardHelper, type: :helper do
  describe '#result_badge_class' do
    it 'returns bad class for scores below 50' do
      expect(helper.result_badge_class(30)).to eq('quiz-result-badge--bad')
      expect(helper.result_badge_class(49)).to eq('quiz-result-badge--bad')
    end

    it 'returns average class for scores between 50 and 75' do
      expect(helper.result_badge_class(50)).to eq('quiz-result-badge--average')
      expect(helper.result_badge_class(74)).to eq('quiz-result-badge--average')
    end

    it 'returns good class for scores 75 and above' do
      expect(helper.result_badge_class(75)).to eq('quiz-result-badge--good')
      expect(helper.result_badge_class(100)).to eq('quiz-result-badge--good')
    end
  end

  describe '#result_badge_text' do
    it 'returns Bad for scores below 50' do
      expect(helper.result_badge_text(30)).to eq('Bad')
      expect(helper.result_badge_text(49)).to eq('Bad')
    end

    it 'returns Average for scores between 50 and 75' do
      expect(helper.result_badge_text(50)).to eq('Average')
      expect(helper.result_badge_text(74)).to eq('Average')
    end

    it 'returns Good for scores 75 and above' do
      expect(helper.result_badge_text(75)).to eq('Good')
      expect(helper.result_badge_text(100)).to eq('Good')
    end
  end

  describe '#get_student_answer' do
    let(:student_id) { 'student-123' }
    let(:question_num) { 1 }

    context 'when answer is nil' do
      before do
        helper.instance_variable_set(:@student_answers, {})
        helper.instance_variable_set(:@questions, {
                                       1 => { text: 'Question 1?', correct_answer: 'Answer A' }
                                     })
      end

      it 'returns empty status with question text' do
        result = helper.get_student_answer(student_id, question_num)
        expect(result[:status]).to eq('is-empty')
        expect(result[:question_text]).to eq('Question 1?')
        expect(result[:answer]).to eq('Poprawna: Answer A')
      end
    end

    context 'when answer is correct' do
      before do
        helper.instance_variable_set(:@student_answers, {
                                       student_id => {
                                         1 => { correct: true, question_text: 'Question 1?', answer: 'Answer A' }
                                       }
                                     })
      end

      it 'returns good status' do
        result = helper.get_student_answer(student_id, question_num)
        expect(result[:status]).to eq('is-good')
        expect(result[:question_text]).to eq('Question 1?')
        expect(result[:answer]).to eq('Answer A')
      end
    end

    context 'when answer is incorrect' do
      before do
        helper.instance_variable_set(:@student_answers, {
                                       student_id => {
                                         1 => { correct: false, question_text: 'Question 1?', answer: 'Wrong Answer' }
                                       }
                                     })
      end

      it 'returns bad status' do
        result = helper.get_student_answer(student_id, question_num)
        expect(result[:status]).to eq('is-bad')
        expect(result[:question_text]).to eq('Question 1?')
        expect(result[:answer]).to eq('Wrong Answer')
      end
    end
  end

  describe '#calculate_student_score' do
    let(:student_id) { 'student-123' }

    context 'when student has correct answers' do
      before do
        helper.instance_variable_set(:@student_answers, {
                                       student_id => {
                                         1 => { correct: true },
                                         2 => { correct: true },
                                         3 => { correct: false }
                                       }
                                     })
      end

      it 'calculates score as 10 points per correct answer' do
        expect(helper.calculate_student_score(student_id)).to eq(20)
      end
    end

    context 'when student has no answers' do
      before do
        helper.instance_variable_set(:@student_answers, {})
      end

      it 'returns 0' do
        expect(helper.calculate_student_score(student_id)).to eq(0)
      end
    end
  end

  describe '#score_class' do
    it 'returns score-great for scores 80-100' do
      expect(helper.score_class(80)).to eq('score-great')
      expect(helper.score_class(100)).to eq('score-great')
    end

    it 'returns score-average for scores 50-79' do
      expect(helper.score_class(50)).to eq('score-average')
      expect(helper.score_class(79)).to eq('score-average')
    end

    it 'returns score-poor for scores below 50' do
      expect(helper.score_class(0)).to eq('score-poor')
      expect(helper.score_class(49)).to eq('score-poor')
    end
  end
end
