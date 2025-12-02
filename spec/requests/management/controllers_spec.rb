# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Management controllers', type: :request do
  include Devise::Test::IntegrationHelpers

  before do
    Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' }
    Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' }
    Rails.application.routes.default_url_options[:host] ||= 'example.com'
  end

  let(:manager_role) { Role.find_by(key: 'school_manager') }
  let(:school) { create(:school) }
  let(:manager) do
    user = create(:user, school: school)
    UserRole.create!(user: user, role: manager_role, school: school)
    user
  end
  let(:manager_without_school) do
    user = create(:user, school: nil)
    UserRole.create!(user: user, role: manager_role, school: school)
    user.update!(school: nil)
    user
  end

  describe 'DashboardController#index' do
    it 'renders dashboard when school present' do
      sign_in manager
      get management_root_path
      expect(response).to have_http_status(:success)
    end

    it 'redirects when school missing' do
      sign_in manager_without_school
      get management_root_path

      expect(response).to redirect_to(authenticated_root_path)
      expect(flash[:alert]).to include('Brak przypisanej szkoły')
    end
  end

  shared_examples 'controller requiring school' do |path_helper|
    it 'renders page when school present' do
      sign_in manager
      get public_send(path_helper)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'AdministrationsController#index' do
    include_examples 'controller requiring school', :management_administration_path
  end

  describe 'TeachersController#index' do
    include_examples 'controller requiring school', :management_teachers_path
  end

  describe 'ParentsController#index' do
    include_examples 'controller requiring school', :management_parents_path
  end

  describe 'StudentsController#index' do
    include_examples 'controller requiring school', :management_students_path
  end

  describe 'ClassesController#index' do
    include_examples 'controller requiring school', :management_classes_path
  end

  describe 'YearsController#index' do
    include_examples 'controller requiring school', :management_years_path
  end

  describe 'NotificationsController#index' do
    let!(:notification) do
      Notification.create!(
        notification_type: 'teacher_awaiting_approval',
        school: school,
        target_role: 'school_manager',
        title: 'Awaiting teacher',
        message: 'Teacher pending approval',
        metadata: { 'teacher_id' => SecureRandom.uuid }
      )
    end

    it 'lists notifications for current manager' do
      sign_in manager
      get management_notifications_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Awaiting teacher')
    end
  end

  describe 'QrCodesController' do
    it 'renders svg for school' do
      sign_in manager
      get management_qr_code_svg_path

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('image/svg+xml')
    end

    it 'returns not found when school missing' do
      sign_in manager_without_school
      get management_qr_code_svg_path
      expect(response).to have_http_status(:not_found)
    end

    it 'sends png data for school' do
      sign_in manager
      get management_qr_code_png_path

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('image/png')
    end
  end
end
