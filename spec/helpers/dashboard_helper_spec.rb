# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardHelper, type: :helper do
  describe '#result_badge_class' do
    it 'returns bad class for scores below 50' do
      expect(helper.result_badge_class(0)).to eq('quiz-result-badge--bad')
      expect(helper.result_badge_class(25)).to eq('quiz-result-badge--bad')
      expect(helper.result_badge_class(49)).to eq('quiz-result-badge--bad')
    end

    it 'returns average class for scores between 50 and 75' do
      expect(helper.result_badge_class(50)).to eq('quiz-result-badge--average')
      expect(helper.result_badge_class(62)).to eq('quiz-result-badge--average')
      expect(helper.result_badge_class(74)).to eq('quiz-result-badge--average')
    end

    it 'returns good class for scores 75 and above' do
      expect(helper.result_badge_class(75)).to eq('quiz-result-badge--good')
      expect(helper.result_badge_class(85)).to eq('quiz-result-badge--good')
      expect(helper.result_badge_class(100)).to eq('quiz-result-badge--good')
    end
  end

  describe '#result_badge_text' do
    it 'returns Bad for scores below 50' do
      expect(helper.result_badge_text(0)).to eq('Bad')
      expect(helper.result_badge_text(25)).to eq('Bad')
      expect(helper.result_badge_text(49)).to eq('Bad')
    end

    it 'returns Average for scores between 50 and 75' do
      expect(helper.result_badge_text(50)).to eq('Average')
      expect(helper.result_badge_text(62)).to eq('Average')
      expect(helper.result_badge_text(74)).to eq('Average')
    end

    it 'returns Good for scores 75 and above' do
      expect(helper.result_badge_text(75)).to eq('Good')
      expect(helper.result_badge_text(85)).to eq('Good')
      expect(helper.result_badge_text(100)).to eq('Good')
    end
  end

  describe '#get_student_answer' do
    let(:student_id) { SecureRandom.uuid }
    let(:question_num) { 1 }

    context 'when answer is nil' do
      before do
        helper.instance_variable_set(:@student_answers, {})
        helper.instance_variable_set(:@questions, nil)
      end

      it 'returns empty status when no answer and no question' do
        result = helper.get_student_answer(student_id, question_num)
        expect(result[:status]).to eq('is-empty')
        expect(result[:question_text]).to be_nil
        expect(result[:answer]).to be_nil
      end

      it 'returns empty status with question info when question exists' do
        questions = {
          1 => { text: 'Test question?', correct_answer: 'Correct answer' }
        }
        helper.instance_variable_set(:@questions, questions)

        result = helper.get_student_answer(student_id, question_num)
        expect(result[:status]).to eq('is-empty')
        expect(result[:question_text]).to eq('Test question?')
        expect(result[:answer]).to eq('Poprawna: Correct answer')
      end
    end

    context 'when answer exists' do
      let(:answers) do
        {
          1 => {
            correct: true,
            question_text: 'Test question?',
            answer: 'Correct answer'
          }
        }
      end

      before do
        helper.instance_variable_set(:@student_answers, { student_id => answers })
      end

      it 'returns is-good status for correct answer' do
        result = helper.get_student_answer(student_id, question_num)
        expect(result[:status]).to eq('is-good')
        expect(result[:question_text]).to eq('Test question?')
        expect(result[:answer]).to eq('Correct answer')
      end

      it 'returns is-bad status for incorrect answer' do
        answers[1][:correct] = false
        answers[1][:answer] = 'Wrong answer'

        result = helper.get_student_answer(student_id, question_num)
        expect(result[:status]).to eq('is-bad')
        expect(result[:question_text]).to eq('Test question?')
        expect(result[:answer]).to eq('Wrong answer')
      end
    end
  end

  describe '#calculate_student_score' do
    let(:student_id) { SecureRandom.uuid }

    context 'when no answers exist' do
      before do
        helper.instance_variable_set(:@student_answers, {})
      end

      it 'returns 0' do
        expect(helper.calculate_student_score(student_id)).to eq(0)
      end
    end

    context 'when answers exist' do
      let(:answers) do
        {
          1 => { correct: true },
          2 => { correct: true },
          3 => { correct: false },
          4 => { correct: true },
          5 => nil
        }
      end

      before do
        helper.instance_variable_set(:@student_answers, { student_id => answers })
      end

      it 'calculates score correctly (10 points per correct answer)' do
        # 3 correct answers * 10 = 30 points
        expect(helper.calculate_student_score(student_id)).to eq(30)
      end
    end
  end

  describe '#score_class' do
    it 'returns score-great for scores 80-100' do
      expect(helper.score_class(80)).to eq('score-great')
      expect(helper.score_class(90)).to eq('score-great')
      expect(helper.score_class(100)).to eq('score-great')
    end

    it 'returns score-good for scores 60-79' do
      expect(helper.score_class(60)).to eq('score-good')
      expect(helper.score_class(70)).to eq('score-good')
      expect(helper.score_class(79)).to eq('score-good')
    end

    it 'returns score-average for scores 40-59' do
      expect(helper.score_class(40)).to eq('score-average')
      expect(helper.score_class(50)).to eq('score-average')
      expect(helper.score_class(59)).to eq('score-average')
    end

    it 'returns score-poor for scores below 40' do
      expect(helper.score_class(0)).to eq('score-poor')
      expect(helper.score_class(20)).to eq('score-poor')
      expect(helper.score_class(39)).to eq('score-poor')
    end
  end
end
