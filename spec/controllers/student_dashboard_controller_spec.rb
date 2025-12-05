# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentDashboardController, type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let!(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:school) { create(:school) }
  let(:student) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: student_role, school: school)
    user
  end

  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: school.current_academic_year_value,
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
  end

  let!(:subject_record) do
    create(:subject, school: nil, title: 'Polska i świat', slug: 'polska-i-swiat',
                     color_light: '#FF6B6B', order_index: 1)
  end
  let!(:unit) { create(:unit, subject: subject_record, title: 'Wprowadzenie', order_index: 1) }
  let!(:learning_module) do
    create(:learning_module, unit: unit, title: 'Polska i świat', slug: 'polska-i-swiat',
                             order_index: 1, published: true)
  end
  let!(:video_content) do
    create(:content, learning_module: learning_module, title: 'Wideo',
                     content_type: 'video', order_index: 1)
  end
  let!(:quiz_content) do
    create(:content, learning_module: learning_module, title: 'Quiz',
                     content_type: 'quiz', order_index: 2,
                     payload: {
                       'questions' => [
                         {
                           'id' => 'q1',
                           'type' => 'single',
                           'text' => 'Stolicą Polski jest:',
                           'options' => [
                             { 'id' => 'a', 'text' => 'Kraków' },
                             { 'id' => 'b', 'text' => 'Warszawa' },
                             { 'id' => 'c', 'text' => 'Gdańsk' }
                           ],
                           'correct' => ['b']
                         },
                         {
                           'id' => 'q2',
                           'type' => 'single',
                           'text' => 'Ile województw ma Polska?',
                           'options' => [
                             { 'id' => 'a', 'text' => '14' },
                             { 'id' => 'b', 'text' => '16' },
                             { 'id' => 'c', 'text' => '18' }
                           ],
                           'correct' => ['b']
                         }
                       ],
                       'pass_threshold' => 80
                     })
  end

  before do
    StudentClassEnrollment.create!(student: student, school_class: school_class, status: 'approved')
    sign_in student
  end

  describe 'GET /home' do
    it 'renders index for authenticated student' do
      get public_home_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Polska i świat')
    end

    it 'redirects non-students to login' do
      sign_out student
      teacher = create(:user, school: school)
      UserRole.create!(user: teacher, role: teacher_role, school: school)
      sign_in teacher

      get public_home_path

      expect(response).to redirect_to(new_user_session_path(role: 'student'))
    end
  end

  describe 'GET /home/subjects/:id' do
    context 'when subject has multiple modules' do
      before do
        create(:learning_module, unit: unit, title: 'Moduł 2', slug: 'modul-2',
                                 order_index: 2, published: true)
      end

      it 'renders subject page with modules list' do
        get student_subject_path(subject_record)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Polska i świat')
        expect(response.body).to include('Moduł 2')
      end
    end

    context 'when subject has only one module' do
      it 'redirects directly to the module' do
        get student_subject_path(subject_record)

        expect(response).to redirect_to(student_module_path(learning_module))
      end
    end

    it 'finds subject by slug' do
      create(:learning_module, unit: unit, title: 'Moduł 2', slug: 'modul-2',
                               order_index: 2, published: true)

      get student_subject_path(id: 'polska-i-swiat')

      expect(response).to have_http_status(:success)
    end

    it 'returns 302 redirect for non-existent subject' do
      get student_subject_path(id: 'non-existent')

      expect(response).to redirect_to(public_home_path)
    end
  end

  describe 'GET /home/modules/:id' do
    it 'renders learning module page' do
      get student_module_path(learning_module)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Polska i świat')
      expect(response.body).to include('Rozpocznij Quiz')
    end

    it 'finds module by slug' do
      get student_module_path(id: 'polska-i-swiat')

      expect(response).to have_http_status(:success)
    end

    it 'redirects for non-existent module' do
      get student_module_path(id: 'non-existent')

      expect(response).to redirect_to(public_home_path)
    end
  end

  describe 'GET /home/modules/:id/quiz' do
    it 'renders quiz page with questions' do
      get student_quiz_path(learning_module)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Stolicą Polski jest:')
      expect(response.body).to include('Warszawa')
      expect(response.body).to include('Kraków')
    end

    it 'logs quiz_start event' do
      expect do
        get student_quiz_path(learning_module)
      end.to change { Event.where(event_type: 'quiz_start').count }.by(1)
    end
  end

  describe 'POST /home/modules/:id/quiz' do
    context 'with all correct answers' do
      let(:correct_answers) { { '0' => '1', '1' => '1' } } # b=index 1 for both questions

      it 'calculates 100% score' do
        post submit_student_quiz_path(learning_module), params: { answers: correct_answers }

        expect(response).to redirect_to(student_result_path(learning_module, score: 100, passed: true))
      end

      it 'creates quiz result with passed=true' do
        post submit_student_quiz_path(learning_module), params: { answers: correct_answers }

        result = QuizResult.find_by(user: student, learning_module: learning_module)
        expect(result.score).to eq(100)
        expect(result.passed).to be true
      end
    end

    context 'with all wrong answers' do
      let(:wrong_answers) { { '0' => '0', '1' => '0' } } # a=index 0, both wrong

      it 'calculates 0% score' do
        post submit_student_quiz_path(learning_module), params: { answers: wrong_answers }

        expect(response).to redirect_to(student_result_path(learning_module, score: 0, passed: false))
      end

      it 'creates quiz result with passed=false' do
        post submit_student_quiz_path(learning_module), params: { answers: wrong_answers }

        result = QuizResult.find_by(user: student, learning_module: learning_module)
        expect(result.passed).to be false
      end
    end

    context 'with mixed answers (50%)' do
      let(:mixed_answers) { { '0' => '1', '1' => '0' } } # first correct, second wrong

      it 'calculates 50% score' do
        post submit_student_quiz_path(learning_module), params: { answers: mixed_answers }

        expect(response).to redirect_to(student_result_path(learning_module, score: 50, passed: false))
      end
    end

    context 'when retaking quiz with worse score' do
      before do
        QuizResult.create!(
          user: student,
          learning_module: learning_module,
          score: 100,
          passed: true,
          completed_at: 1.day.ago
        )
      end

      it 'keeps the best score in database' do
        post submit_student_quiz_path(learning_module), params: { answers: { '0' => '0', '1' => '0' } }

        result = QuizResult.find_by(user: student, learning_module: learning_module)
        expect(result.score).to eq(100) # Best score preserved
      end

      it 'shows current attempt score on result page' do
        post submit_student_quiz_path(learning_module), params: { answers: { '0' => '0', '1' => '0' } }

        # Redirects with current score in params
        expect(response).to redirect_to(student_result_path(learning_module, score: 0, passed: false))
      end
    end

    it 'logs quiz_complete event' do
      initial_count = Event.where(event_type: 'quiz_complete').count
      post submit_student_quiz_path(learning_module), params: { answers: { '0' => '1', '1' => '1' } }
      expect(Event.where(event_type: 'quiz_complete').count).to be > initial_count
    end
  end

  describe 'GET /home/modules/:id/result' do
    context 'with quiz result' do
      before do
        QuizResult.create!(
          user: student,
          learning_module: learning_module,
          score: 85,
          passed: true,
          details: { 'correct_count' => 2, 'total' => 2 },
          completed_at: Time.current
        )
      end

      it 'renders result page' do
        get student_result_path(learning_module)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('85')
      end

      it 'shows passed message for score >= 80' do
        get student_result_path(learning_module)

        expect(response.body).to include('Gratulacje')
      end

      it 'uses score from params if provided' do
        get student_result_path(learning_module, score: 50, passed: false)

        expect(response.body).to include('50')
        expect(response.body).to include('Spróbuj ponownie')
      end
    end

    context 'without quiz result' do
      it 'redirects to quiz page' do
        get student_result_path(learning_module)

        expect(response).to redirect_to(student_quiz_path(learning_module))
      end
    end
  end

  describe 'completed subject display on /home' do
    before do
      QuizResult.create!(
        user: student,
        learning_module: learning_module,
        score: 100,
        passed: true,
        completed_at: Time.current
      )
    end

    it 'shows completed styling for subjects with >= 80% completion' do
      get public_home_path

      expect(response.body).to include('class-result--completed')
      expect(response.body).to include('100%')
    end
  end
end
