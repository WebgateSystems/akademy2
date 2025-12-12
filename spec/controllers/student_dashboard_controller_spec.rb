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

      expect(response).to redirect_to(student_login_path)
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
        create(:certificate, quiz_result: QuizResult.first)
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

  describe 'GET /home/notifications' do
    let!(:unread_notification_1) do
      create(:notification,
             user: student,
             school: school,
             notification_type: 'student_video_approved',
             title: 'Film zatwierdzony',
             message: 'Twój film został zatwierdzony',
             target_role: 'student',
             read_at: nil)
    end

    let!(:unread_notification_2) do
      create(:notification,
             user: nil,
             school: school,
             notification_type: 'student_video_rejected',
             title: 'Film odrzucony',
             message: 'Twój film został odrzucony',
             target_role: 'student',
             read_at: nil)
    end

    let!(:read_notification) do
      create(:notification,
             user: student,
             school: school,
             notification_type: 'quiz_completed',
             title: 'Quiz ukończony',
             message: 'Ukończyłeś quiz',
             target_role: 'student',
             read_at: 1.day.ago)
    end

    context 'when viewing unread notifications' do
      it 'returns http success' do
        get student_notifications_path(status: 'unread')
        expect(response).to have_http_status(:success)
      end

      it 'displays only unread notifications' do
        get student_notifications_path(status: 'unread')
        expect(response.body).to include('Film zatwierdzony')
        expect(response.body).to include('Film odrzucony')
        expect(response.body).not_to include('Quiz ukończony')
      end

      it 'sets correct unread count' do
        get student_notifications_path(status: 'unread')
        expect(assigns(:unread_count)).to eq(2)
      end

      it 'shows mark all as read button when there are unread notifications' do
        get student_notifications_path(status: 'unread')
        expect(response.body).to include('Oznacz wszystkie jako przeczytane')
      end
    end

    context 'when viewing archived notifications' do
      it 'returns http success' do
        get student_notifications_path(status: 'archived')
        expect(response).to have_http_status(:success)
      end

      it 'displays only read notifications' do
        get student_notifications_path(status: 'archived')
        expect(response.body).to include('Quiz ukończony')
        expect(response.body).not_to include('Film zatwierdzony')
        expect(response.body).not_to include('Film odrzucony')
      end

      it 'does not show mark all as read button' do
        get student_notifications_path(status: 'archived')
        expect(response.body).not_to include('Oznacz wszystkie jako przeczytane')
      end
    end

    context 'when there are no notifications' do
      before do
        Notification.delete_all
      end

      it 'shows empty state' do
        get student_notifications_path(status: 'unread')
        expect(response.body).to include('Brak powiadomień')
      end
    end

    context 'with notifications for other students' do
      let(:other_student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        user
      end

      let!(:other_student_personal_notification) do
        # Notification with user_id set to other student - should NOT be visible
        create(:notification,
               user: other_student,
               school: school,
               notification_type: 'student_video_approved',
               title: 'Inny film osobisty',
               message: 'Film innego ucznia (osobisty)',
               target_role: 'student',
               read_at: nil)
      end

      let!(:school_wide_notification) do
        # Notification without user_id but with target_role=student - SHOULD be visible
        create(:notification,
               user: nil,
               school: school,
               notification_type: 'student_video_approved',
               title: 'Powiadomienie szkolne',
               message: 'Powiadomienie dla wszystkich studentów',
               target_role: 'student',
               read_at: nil)
      end

      it 'does not show personal notifications for other students' do
        get student_notifications_path(status: 'unread')
        expect(response.body).not_to include('Inny film osobisty')
      end

      it 'shows school-wide notifications for student role' do
        get student_notifications_path(status: 'unread')
        expect(response.body).to include('Powiadomienie szkolne')
      end
    end
  end

  describe 'POST /home/notifications/mark_as_read' do
    let!(:notification_1) do
      create(:notification,
             user: student,
             school: school,
             notification_type: 'student_video_approved',
             title: 'Film zatwierdzony',
             message: 'Twój film został zatwierdzony',
             target_role: 'student',
             read_at: nil)
    end

    let!(:notification_2) do
      create(:notification,
             user: nil,
             school: school,
             notification_type: 'student_video_rejected',
             title: 'Film odrzucony',
             message: 'Twój film został odrzucony',
             target_role: 'student',
             read_at: nil)
    end

    let!(:notification_3) do
      create(:notification,
             user: student,
             school: school,
             notification_type: 'quiz_completed',
             title: 'Quiz ukończony',
             message: 'Ukończyłeś quiz',
             target_role: 'student',
             read_at: nil)
    end

    let!(:other_student_notification) do
      other_student = create(:user, school: school)
      UserRole.create!(user: other_student, role: student_role, school: school)
      create(:notification,
             user: other_student,
             school: school,
             notification_type: 'student_video_approved',
             title: 'Inny film',
             message: 'Film innego ucznia',
             target_role: 'student',
             read_at: nil)
    end

    context 'when marking single notification as read' do
      it 'marks notification as read' do
        expect do
          post mark_student_notifications_as_read_path,
               params: { notification_ids: [notification_1.id] }
        end.to change { notification_1.reload.read_at }.from(nil)
      end

      it 'returns success response' do
        post mark_student_notifications_as_read_path,
             params: { notification_ids: [notification_1.id] }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['marked_count']).to eq(1)
      end

      it 'does not mark other notifications' do
        post mark_student_notifications_as_read_path,
             params: { notification_ids: [notification_1.id] }

        expect(notification_2.reload.read_at).to be_nil
        expect(notification_3.reload.read_at).to be_nil
      end
    end

    context 'when marking multiple notifications as read' do
      it 'marks all specified notifications as read' do
        expect do
          post mark_student_notifications_as_read_path,
               params: { notification_ids: [notification_1.id, notification_2.id, notification_3.id] }
        end.to change { notification_1.reload.read_at }.from(nil)
                                                       .and change { notification_2.reload.read_at }.from(nil)
                                                                                                    .and change {
                                                                                                           notification_3.reload.read_at
                                                                                                         }.from(nil)
      end

      it 'returns correct marked count' do
        post mark_student_notifications_as_read_path,
             params: { notification_ids: [notification_1.id, notification_2.id, notification_3.id] }

        json_response = JSON.parse(response.body)
        expect(json_response['marked_count']).to eq(3)
      end
    end

    context 'when marking notification without user_id' do
      it 'marks notification with target_role=student and school_id as read' do
        expect do
          post mark_student_notifications_as_read_path,
               params: { notification_ids: [notification_2.id] }
        end.to change { notification_2.reload.read_at }.from(nil)
      end
    end

    context 'when trying to mark other student notification' do
      let(:other_student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        user
      end

      let!(:other_student_notification) do
        create(:notification,
               user: other_student,
               school: school,
               notification_type: 'student_video_approved',
               title: 'Other student video',
               message: 'Video from other student',
               target_role: 'student',
               read_at: nil)
      end

      it 'does not mark notification for other student' do
        expect do
          post mark_student_notifications_as_read_path,
               params: { notification_ids: [other_student_notification.id] }
        end.not_to(change { other_student_notification.reload.read_at })
      end
    end

    context 'when marking notification with wrong notification_type' do
      let!(:wrong_type_notification) do
        create(:notification,
               user: student,
               school: school,
               notification_type: 'teacher_awaiting_approval',
               title: 'Wrong type',
               message: 'Wrong notification type',
               target_role: 'teacher',
               read_at: nil)
      end

      it 'does not mark notification with wrong type' do
        expect do
          post mark_student_notifications_as_read_path,
               params: { notification_ids: [wrong_type_notification.id] }
        end.not_to(change { wrong_type_notification.reload.read_at })
      end
    end

    context 'when notification_ids is empty' do
      it 'returns success with zero count' do
        post mark_student_notifications_as_read_path,
             params: { notification_ids: [] }

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['marked_count']).to eq(0)
      end
    end

    context 'when notification_ids is nil' do
      it 'returns success with zero count' do
        post mark_student_notifications_as_read_path,
             params: {}

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['marked_count']).to eq(0)
      end
    end
  end

  describe 'notification count in top bar' do
    before do
      create(:notification,
             user: student,
             school: school,
             notification_type: 'student_video_approved',
             title: 'Film zatwierdzony',
             message: 'Twój film został zatwierdzony',
             target_role: 'student',
             read_at: nil)

      create(:notification,
             user: nil,
             school: school,
             notification_type: 'student_video_rejected',
             title: 'Film odrzucony',
             message: 'Twój film został odrzucony',
             target_role: 'student',
             read_at: nil)
    end

    it 'counts unread notifications correctly' do
      get public_home_path
      expect(assigns(:notifications_count)).to eq(2)
    end

    it 'includes notifications without user_id but with target_role=student' do
      get public_home_path
      expect(assigns(:notifications_count)).to eq(2)
    end

    context 'when all notifications are read' do
      before do
        Notification.update_all(read_at: Time.current)
      end

      it 'returns zero count' do
        get public_home_path
        expect(assigns(:notifications_count)).to eq(0)
      end
    end
  end

  describe 'GET /home/videos' do
    it 'renders school videos page' do
      get student_videos_path
      expect(response).to have_http_status(:success)
    end

    context 'with student videos' do
      let!(:student_video) do
        StudentVideo.create!(
          user: student,
          school: school,
          subject: subject_record,
          title: 'My Test Video',
          description: 'Video description',
          status: 'pending',
          file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/test.mp4'), 'video/mp4')
        )
      end

      it 'displays student videos' do
        get student_videos_path
        expect(response.body).to include('My Test Video')
      end
    end
  end

  describe 'DELETE /home/videos/:id' do
    let!(:pending_video) do
      StudentVideo.create!(
        user: student,
        school: school,
        subject: subject_record,
        title: 'Video to delete',
        description: 'Test',
        status: 'pending',
        file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/test.mp4'), 'video/mp4')
      )
    end

    it 'deletes pending video owned by student' do
      expect do
        delete destroy_student_video_path(pending_video)
      end.to change(StudentVideo, :count).by(-1)
    end

    it 'redirects to videos page with notice' do
      delete destroy_student_video_path(pending_video)
      expect(response).to redirect_to(student_videos_path)
      expect(flash[:notice]).to be_present
    end

    context 'with approved video' do
      before { pending_video.update!(status: 'approved', moderated_at: Time.current) }

      it 'does not delete approved video' do
        expect do
          delete destroy_student_video_path(pending_video)
        end.not_to change(StudentVideo, :count)
      end

      it 'redirects with alert' do
        delete destroy_student_video_path(pending_video)
        expect(flash[:alert]).to be_present
      end
    end

    context 'with video from another student' do
      let(:other_student) do
        user = create(:user, school: school)
        UserRole.create!(user: user, role: student_role, school: school)
        user
      end

      let!(:other_video) do
        StudentVideo.create!(
          user: other_student,
          school: school,
          subject: subject_record,
          title: 'Other student video',
          description: 'Test',
          status: 'pending',
          file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/test.mp4'), 'video/mp4')
        )
      end

      it 'does not allow deleting other student video' do
        expect do
          delete destroy_student_video_path(other_video)
        end.not_to change(StudentVideo, :count)
      end

      it 'redirects with alert' do
        delete destroy_student_video_path(other_video)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'POST /home/contents/:id/toggle_like' do
    it 'toggles like on video content' do
      post toggle_content_like_path(video_content), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['liked']).to be true
    end

    it 'unlikes previously liked content' do
      ContentLike.create!(user: student, content: video_content)
      post toggle_content_like_path(video_content), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['liked']).to be false
    end

    context 'with quiz content (not likeable)' do
      it 'returns error for quiz content' do
        post toggle_content_like_path(quiz_content), as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /home/videos/waiting' do
    let!(:pending_video) do
      StudentVideo.create!(
        user: student,
        school: school,
        subject: subject_record,
        title: 'Pending Video',
        description: 'Test',
        status: 'pending',
        file: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/test.mp4'), 'video/mp4')
      )
    end

    it 'renders video waiting page' do
      get student_video_waiting_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /home/account' do
    it 'renders account page' do
      get student_account_path
      expect(response).to have_http_status(:success)
    end

    it 'shows user full name as read-only' do
      get student_account_path
      # Use CGI.escapeHTML to handle names with apostrophes (e.g., O'Conner -> O&#39;Conner)
      expect(response.body).to include(CGI.escapeHTML(student.full_name))
    end

    it 'shows link to settings' do
      get student_account_path
      expect(response.body).to include(student_settings_path)
    end
  end

  describe 'PATCH /home/account' do
    context 'when email is unverified' do
      let(:unverified_student) do
        user = create(:user, school: school, confirmed_at: nil)
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        user
      end

      before do
        sign_out student
        sign_in unverified_student
      end

      it 'allows updating email' do
        patch student_account_path, params: { user: { email: 'newemail@example.com' } }
        unverified_student.reload
        # With skip_reconfirmation!, email should be updated directly
        expect(unverified_student.email).to eq('newemail@example.com')
      end
    end

    context 'when email is verified' do
      it 'does not allow updating email and redirects with notice' do
        old_email = student.email
        patch student_account_path, params: { user: { email: 'newemail@example.com' } }
        expect(student.reload.email).to eq(old_email)
        expect(response).to redirect_to(student_account_path)
      end
    end

    context 'when phone is unverified' do
      before { student.update!(metadata: { 'phone_verified' => false }) }

      it 'allows updating phone' do
        patch student_account_path, params: { user: { phone: '+48123456789' } }
        expect(student.reload.phone).to eq('+48123456789')
      end
    end

    context 'when phone is verified' do
      before { student.update!(phone: '+48111222333', metadata: { 'phone_verified' => true }) }

      it 'does not allow updating phone' do
        patch student_account_path, params: { user: { phone: '+48999888777' } }
        expect(student.reload.phone).to eq('+48111222333')
      end
    end
  end

  describe 'GET /home/account/settings' do
    it 'renders settings page' do
      get student_settings_path
      expect(response).to have_http_status(:success)
    end

    it 'shows theme selector' do
      get student_settings_path
      expect(response.body).to include('theme')
    end

    it 'shows language selector' do
      get student_settings_path
      expect(response.body).to include('locale')
    end

    it 'shows PIN input fields' do
      get student_settings_path
      expect(response.body).to include('new_pin')
      expect(response.body).to include('confirm_pin')
    end
  end

  describe 'PATCH /home/account/settings' do
    context 'when changing locale' do
      it 'updates user locale' do
        patch student_settings_path, params: { user: { locale: 'pl', theme: 'light' } }
        expect(student.reload.locale).to eq('pl')
      end

      it 'redirects to account page with notice' do
        patch student_settings_path, params: { user: { locale: 'en', theme: 'dark' } }
        expect(response).to redirect_to(student_account_path)
        expect(flash[:notice]).to be_present
      end
    end

    context 'when changing PIN' do
      context 'with valid 4-digit PIN' do
        it 'updates password successfully' do
          patch student_settings_path, params: {
            user: { new_pin: '1234', pin_confirmation: '1234', theme: 'light', locale: 'en' }
          }
          expect(response).to redirect_to(student_account_path)
          expect(student.reload.valid_password?('1234')).to be true
        end
      end

      context 'with mismatched PIN confirmation' do
        it 'returns error' do
          patch student_settings_path, params: {
            user: { new_pin: '1234', pin_confirmation: '5678', theme: 'light', locale: 'en' }
          }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with PIN shorter than 4 digits' do
        it 'returns error' do
          patch student_settings_path, params: {
            user: { new_pin: '123', pin_confirmation: '123', theme: 'light', locale: 'en' }
          }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with PIN longer than 4 digits' do
        it 'returns error' do
          patch student_settings_path, params: {
            user: { new_pin: '12345', pin_confirmation: '12345', theme: 'light', locale: 'en' }
          }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with non-numeric PIN' do
        it 'returns error' do
          patch student_settings_path, params: {
            user: { new_pin: 'abcd', pin_confirmation: 'abcd', theme: 'light', locale: 'en' }
          }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'POST /home/account/request-deletion' do
    let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
    let!(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }

    let!(:principal) do
      user = create(:user, school: school)
      UserRole.create!(user: user, role: principal_role, school: school)
      user
    end

    it 'creates account deletion request notification' do
      expect do
        post request_student_account_deletion_path
      end.to change(Notification, :count).by(1)
    end

    it 'creates notification with correct type and metadata' do
      post request_student_account_deletion_path
      notification = Notification.find_by(notification_type: 'account_deletion_request')
      expect(notification).to be_present
      expect(notification.metadata['user_id']).to eq(student.id)
    end

    it 'redirects to account page with notice' do
      post request_student_account_deletion_path
      expect(response).to redirect_to(student_account_path)
      expect(flash[:notice]).to be_present
    end

    it 'does not delete the account immediately' do
      expect do
        post request_student_account_deletion_path
      end.not_to change(User, :count)
    end
  end
end
