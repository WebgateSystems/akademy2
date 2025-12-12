# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe QuizResultsPdf do
  let(:school) { create(:school) }
  let(:school_class) do
    SchoolClass.create!(
      school: school, name: '4A', year: '2025/2026', qr_token: SecureRandom.uuid, metadata: {}
    )
  end
  let(:teacher) { create(:user, school: school, first_name: 'Jan', last_name: 'Nauczyciel') }
  let(:subject_record) { create(:subject, school: school, title: 'Matematyka') }
  let(:unit) { create(:unit, subject: subject_record) }
  let(:learning_module) { create(:learning_module, unit: unit, title: 'Algebra') }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let!(:student) do
    user = create(:user, school: school, first_name: 'Anna', last_name: 'Kowalska')
    UserRole.create!(user: user, role: student_role, school: school)
    StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
    user
  end
  let(:questions) do
    {
      1 => { text: 'Pytanie 1?', options: [{ id: 'a', text: 'Opcja A' }], correct: ['a'] },
      2 => { text: 'Pytanie 2?', options: [{ id: 'b', text: 'Opcja B' }], correct: ['b'] }
    }
  end
  let(:student_answers) do
    {
      student.id => {
        1 => { question_text: 'Pytanie 1?', answer: 'Opcja A', correct: true },
        2 => { question_text: 'Pytanie 2?', answer: 'Opcja B', correct: true }
      }
    }
  end
  let(:distribution) { { no_results: 0, bad_results: 0, average_results: 0, great_results: 100 } }

  describe '.build' do
    it 'generates valid PDF data' do
      pdf_data = described_class.build(
        subject: subject_record,
        school_class: school_class,
        school: school,
        students: [student],
        questions: questions,
        student_answers: student_answers,
        completion_rate: 100,
        average_score: 100,
        distribution: distribution,
        teacher: teacher
      )

      expect(pdf_data).to be_present
      expect(pdf_data[0..3]).to eq('%PDF')
    end

    it 'generates PDF with reasonable size' do
      pdf_data = described_class.build(
        subject: subject_record,
        school_class: school_class,
        school: school,
        students: [student],
        questions: questions,
        student_answers: student_answers,
        completion_rate: 100,
        average_score: 100,
        distribution: distribution,
        teacher: teacher
      )

      expect(pdf_data.bytesize).to be > 1000
    end

    context 'with empty students list' do
      it 'generates PDF without errors' do
        pdf_data = described_class.build(
          subject: subject_record,
          school_class: school_class,
          school: school,
          students: [],
          questions: questions,
          student_answers: {},
          completion_rate: 0,
          average_score: 0,
          distribution: { no_results: 100, bad_results: 0, average_results: 0, great_results: 0 },
          teacher: teacher
        )

        expect(pdf_data).to be_present
        expect(pdf_data[0..3]).to eq('%PDF')
      end
    end

    context 'with Polish characters in names' do
      let!(:polish_student) do
        user = create(:user, school: school, first_name: 'Żółć', last_name: 'Źródło')
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        user
      end

      let(:polish_answers) do
        {
          polish_student.id => {
            1 => { question_text: 'Pytanie?', answer: 'Łódź', correct: true }
          }
        }
      end

      it 'handles Polish characters correctly' do
        pdf_data = described_class.build(
          subject: subject_record,
          school_class: school_class,
          school: school,
          students: [polish_student],
          questions: questions,
          student_answers: polish_answers,
          completion_rate: 100,
          average_score: 100,
          distribution: distribution,
          teacher: teacher
        )

        expect(pdf_data).to be_present
        expect(pdf_data[0..3]).to eq('%PDF')
      end
    end

    context 'with many students' do
      let(:many_students) do
        Array.new(10) do |i|
          user = create(:user, school: school, first_name: "Student#{i}", last_name: "Test#{i}")
          UserRole.create!(user: user, role: student_role, school: school)
          StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
          user
        end
      end

      let(:many_answers) do
        many_students.each_with_object({}) do |student, hash|
          hash[student.id] = {
            1 => { question_text: 'Pytanie 1?', answer: 'Opcja A', correct: true },
            2 => { question_text: 'Pytanie 2?', answer: 'Opcja B', correct: false }
          }
        end
      end

      it 'generates PDF for multiple students' do
        pdf_data = described_class.build(
          subject: subject_record,
          school_class: school_class,
          school: school,
          students: many_students,
          questions: questions,
          student_answers: many_answers,
          completion_rate: 100,
          average_score: 50,
          distribution: { no_results: 0, bad_results: 0, average_results: 100, great_results: 0 },
          teacher: teacher
        )

        expect(pdf_data).to be_present
        expect(pdf_data[0..3]).to eq('%PDF')
        # PDF should be larger with more students
        expect(pdf_data.bytesize).to be > 2000
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
