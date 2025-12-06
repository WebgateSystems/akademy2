# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ResourcesController, type: :controller do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin) do
    user = create(:user)
    UserRole.create!(user: user, role: admin_role)
    user
  end

  before do
    session[:admin_id] = Jwt::TokenService.encode({ user_id: admin.id })
  end

  describe 'RESOURCES constant' do
    it 'defines all available resources' do
      expect(described_class::RESOURCES.keys).to include(
        'users', 'schools', 'subjects', 'units', 'learning_modules', 'contents'
      )
    end
  end

  describe 'GET #index' do
    context 'for schools' do
      it 'returns success' do
        get :index, params: { resource: 'schools' }
        expect(response).to have_http_status(:ok)
      end

      it 'renders schools template' do
        get :index, params: { resource: 'schools' }
        expect(response).to render_template('admin/resources/schools')
      end
    end

    context 'for subjects' do
      it 'returns success' do
        get :index, params: { resource: 'subjects' }
        expect(response).to have_http_status(:ok)
      end

      it 'renders subjects template' do
        get :index, params: { resource: 'subjects' }
        expect(response).to render_template('admin/resources/subjects')
      end
    end

    context 'for unknown resource' do
      it 'returns not found' do
        get :index, params: { resource: 'unknown' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #show' do
    context 'for subject' do
      let(:subject_record) { create(:subject) }

      it 'returns success' do
        get :show, params: { resource: 'subjects', id: subject_record.id }
        expect(response).to have_http_status(:ok)
      end

      it 'renders subjects_show template' do
        get :show, params: { resource: 'subjects', id: subject_record.id }
        expect(response).to render_template('admin/resources/subjects_show')
      end
    end
  end

  describe 'GET #new' do
    context 'for subject' do
      it 'returns success' do
        get :new, params: { resource: 'subjects' }
        expect(response).to have_http_status(:ok)
      end

      it 'renders subjects_new template' do
        get :new, params: { resource: 'subjects' }
        expect(response).to render_template('admin/resources/subjects_new')
      end
    end
  end

  describe 'POST #reorder_subjects' do
    let!(:subject1) { create(:subject, order_index: 1) }
    let!(:subject2) { create(:subject, order_index: 2) }

    it 'reorders subjects' do
      post :reorder_subjects, params: { subject_ids: [subject2.id, subject1.id] }
      expect(response).to have_http_status(:ok)
    end

    it 'returns bad_request for invalid params' do
      post :reorder_subjects, params: { subject_ids: 'invalid' }
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns bad_request for invalid UUIDs' do
      post :reorder_subjects, params: { subject_ids: %w[invalid-uuid another-invalid] }
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'helper methods' do
    describe '#polish_pluralize' do
      let(:controller_instance) { described_class.new }

      it 'returns singular suffix for 1' do
        result = controller_instance.polish_pluralize(1, 'singular', 'plural2-4', 'plural5+')
        expect(result).to eq('singular')
      end

      it 'returns 2-4 suffix for 3' do
        result = controller_instance.polish_pluralize(3, 'singular', 'plural2-4', 'plural5+')
        expect(result).to eq('plural2-4')
      end

      it 'returns 5+ suffix for 10' do
        result = controller_instance.polish_pluralize(10, 'singular', 'plural2-4', 'plural5+')
        expect(result).to eq('plural5+')
      end
    end
  end
end
