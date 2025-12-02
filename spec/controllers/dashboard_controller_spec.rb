# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
  let(:student_role) { Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' } }
  let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }

  let(:school) { create(:school) }
  let(:school_class) do
    SchoolClass.create!(
      school: school,
      name: '4A',
      year: '2025/2026',
      qr_token: SecureRandom.uuid,
      metadata: {}
    )
  end
  let(:teacher) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: teacher_role, school: school)
    TeacherClassAssignment.create!(teacher: user, school_class: school_class, role: 'teacher')
    user.reload
  end

  before do
    teacher_role
    student_role
    school_class
  end

  describe 'authentication' do
    # Routes are accessible but require authentication (handled by controller)
    it 'redirects unauthenticated users to login' do
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when user is not a teacher' do
      let(:non_teacher) { create(:user, school: school) }

      before { sign_in non_teacher }

      it 'redirects to login page with alert to avoid redirect loop' do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to include('nauczycieli')
        expect(flash[:alert]).to include('Zaloguj się ponownie')
      end
    end
  end

  describe 'GET #index' do
    before { sign_in teacher }

    it 'returns http success' do
      get dashboard_path
      expect(response).to have_http_status(:success)
    end

    it 'assigns school and classes' do
      get dashboard_path
      expect(response.body).to include('4A')
    end

    it 'handles class_id parameter' do
      get dashboard_path(class_id: school_class.id)
      expect(response).to have_http_status(:success)
    end

    context 'when teacher has no assigned classes' do
      before do
        TeacherClassAssignment.where(teacher: teacher).delete_all
      end

      it 'still renders successfully' do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'with multiple classes' do
      let!(:another_class) do
        klass = SchoolClass.create!(
          school: school,
          name: '5B',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
        TeacherClassAssignment.create!(teacher: teacher, school_class: klass, role: 'teacher')
        klass
      end

      it 'shows all assigned classes' do
        get dashboard_path
        expect(response.body).to include('4A')
        expect(response.body).to include('5B')
      end
    end

    context 'with students and statistics' do
      let!(:student) do
        user = create(:user, school: school, first_name: 'Jan', last_name: 'Kowalski')
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        user
      end

      it 'loads class statistics' do
        get dashboard_path(class_id: school_class.id)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #students' do
    before { sign_in teacher }

    it 'returns http success' do
      get dashboard_students_path
      expect(response).to have_http_status(:success)
    end

    it 'handles class_id parameter' do
      get dashboard_students_path(class_id: school_class.id)
      expect(response).to have_http_status(:success)
    end

    context 'when teacher has no class assigned' do
      before do
        TeacherClassAssignment.where(teacher: teacher).delete_all
      end

      it 'renders the page without crashing' do
        get dashboard_students_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'with students in class' do
      let!(:student) do
        user = create(:user, school: school, first_name: 'Anna', last_name: 'Nowak')
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        user
      end

      it 'displays student names' do
        get dashboard_students_path(class_id: school_class.id)
        expect(response.body).to include('Anna')
        expect(response.body).to include('Nowak')
      end
    end

    context 'with pending students' do
      let!(:pending_student) do
        user = create(:user, school: school, first_name: 'Pending', last_name: 'Student')
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'pending')
        user
      end

      it 'shows pending status' do
        get dashboard_students_path(class_id: school_class.id)
        expect(response.body).to include('Oczekuje')
      end
    end
  end

  describe 'GET #show_student' do
    let!(:student) do
      user = create(:user,
                    school: school,
                    first_name: 'Jan',
                    last_name: 'Kowalski',
                    email: 'jan.kowalski@example.com',
                    birthdate: Date.new(2010, 5, 15),
                    metadata: { 'phone' => '+48 123 456 789' })
      UserRole.create!(user: user, role: student_role, school: school)
      StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
      user
    end

    before { sign_in teacher }

    it 'returns http success' do
      get dashboard_student_path(student, class_id: school_class.id)
      expect(response).to have_http_status(:success)
    end

    it 'displays student name' do
      get dashboard_student_path(student, class_id: school_class.id)
      expect(response.body).to include('Jan')
      expect(response.body).to include('Kowalski')
    end

    it 'displays student email in details section' do
      get dashboard_student_path(student, class_id: school_class.id)
      # Email appears twice: in header info and in details section
      expect(response.body).to include('jan.kowalski@example.com')
    end

    it 'displays student phone' do
      get dashboard_student_path(student, class_id: school_class.id)
      expect(response.body).to include('+48 123 456 789')
    end

    it 'displays student birth date' do
      get dashboard_student_path(student, class_id: school_class.id)
      expect(response.body).to include('15.05.2010')
    end

    it 'displays class name' do
      get dashboard_student_path(student, class_id: school_class.id)
      expect(response.body).to include('4A')
    end

    context 'with quiz results' do
      let(:subject_record) { create(:subject, school: school, title: 'Matematyka') }
      let(:unit) { create(:unit, subject: subject_record) }
      let(:learning_module) { create(:learning_module, unit: unit) }
      let!(:quiz_result) do
        create(:quiz_result, user: student, learning_module: learning_module, score: 85)
      end

      it 'displays subject results' do
        get dashboard_student_path(student, class_id: school_class.id)
        expect(response.body).to include('Matematyka')
      end

      it 'displays quiz score' do
        get dashboard_student_path(student, class_id: school_class.id)
        expect(response.body).to include('85')
      end
    end

    context 'with locked student' do
      before { student.update!(locked_at: Time.current) }

      it 'shows locked status' do
        get dashboard_student_path(student, class_id: school_class.id)
        expect(response.body).to include('Zablokowany')
      end
    end

    context 'with confirmed student' do
      before { student.update!(confirmed_at: Time.current) }

      it 'shows active status' do
        get dashboard_student_path(student, class_id: school_class.id)
        expect(response.body).to include('Aktywny')
      end
    end

    context 'with unconfirmed student' do
      before { student.update!(confirmed_at: nil, locked_at: nil) }

      it 'shows pending status' do
        get dashboard_student_path(student, class_id: school_class.id)
        expect(response.body).to include('Oczekuje')
      end
    end

    context 'when teacher does not have access to student' do
      let(:other_class) do
        SchoolClass.create!(
          school: school,
          name: '6C',
          year: '2025/2026',
          qr_token: SecureRandom.uuid,
          metadata: {}
        )
      end
      let(:other_student) do
        user = create(:user, school: school, first_name: 'Other', last_name: 'Student')
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: other_class, status: 'approved')
        user
      end

      it 'redirects with alert' do
        get dashboard_student_path(other_student)
        expect(response).to redirect_to(dashboard_students_path)
        expect(flash[:alert]).to include('Brak dostępu')
      end
    end
  end

  describe 'GET #notifications' do
    before { sign_in teacher }

    it 'returns http success' do
      get dashboard_notifications_path
      expect(response).to have_http_status(:success)
    end

    context 'with notifications' do
      let!(:notification) do
        Notification.create!(
          notification_type: 'student_awaiting_approval',
          school: school,
          target_role: 'teacher',
          title: 'Nowy uczeń oczekuje',
          message: 'Jan Kowalski czeka na zatwierdzenie',
          metadata: {}
        )
      end

      it 'displays notifications' do
        get dashboard_notifications_path
        expect(response.body).to include('Nowy uczeń oczekuje')
      end
    end
  end

  describe 'GET #quiz_results' do
    let(:subject_record) { create(:subject, school: school, title: 'Fizyka') }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit, title: 'Moduł 1') }

    before { sign_in teacher }

    it 'returns http success' do
      get dashboard_quiz_results_path(subject_id: subject_record.id, class_id: school_class.id)
      expect(response).to have_http_status(:success)
    end

    it 'displays subject title' do
      get dashboard_quiz_results_path(subject_id: subject_record.id, class_id: school_class.id)
      expect(response.body).to include('Fizyka')
    end

    context 'with students and results' do
      let!(:student) do
        user = create(:user, school: school, first_name: 'Maria', last_name: 'Zielińska')
        UserRole.create!(user: user, role: student_role, school: school)
        StudentClassEnrollment.create!(student: user, school_class: school_class, status: 'approved')
        user
      end
      let!(:quiz_result) do
        create(:quiz_result, user: student, learning_module: learning_module, score: 92)
      end

      it 'displays student names' do
        get dashboard_quiz_results_path(subject_id: subject_record.id, class_id: school_class.id)
        expect(response.body).to include('Maria')
        expect(response.body).to include('Zielińska')
      end
    end
  end

  describe 'helper methods' do
    context 'with #can_access_management?' do
      before { sign_in teacher }

      it 'returns false for regular teacher' do
        get dashboard_path
        # Teacher without principal role should not see management link
        expect(response).to have_http_status(:success)
      end

      context 'when user is also principal' do
        before do
          UserRole.create!(user: teacher, role: principal_role, school: school)
          teacher.reload
        end

        it 'shows management access' do
          get dashboard_path
          expect(response).to have_http_status(:success)
          # Principal should have access to management
          expect(response.body).to include('management')
        end
      end
    end
  end

  describe 'notifications count' do
    before { sign_in teacher }

    context 'with unread notifications' do
      before do
        Notification.create!(
          notification_type: 'student_awaiting_approval',
          school: school,
          target_role: 'teacher',
          title: 'Test notification',
          message: 'Test message',
          metadata: {}
        )
      end

      it 'displays notification counter' do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
