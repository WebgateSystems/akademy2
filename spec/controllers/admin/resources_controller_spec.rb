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

  describe 'GET #edit' do
    context 'for subject' do
      let(:subject_record) { create(:subject) }

      it 'returns success' do
        get :edit, params: { resource: 'subjects', id: subject_record.id }
        expect(response).to have_http_status(:ok)
      end

      it 'renders subjects_edit template' do
        get :edit, params: { resource: 'subjects', id: subject_record.id }
        expect(response).to render_template('admin/resources/subjects_edit')
      end
    end
  end

  describe 'POST #create' do
    context 'for subject' do
      let(:valid_params) do
        { resource: 'subjects', subject: { title: 'New Subject', description: 'Test description' } }
      end

      it 'creates a new subject' do
        expect do
          post :create, params: valid_params
        end.to change(Subject, :count).by(1)
      end

      it 'redirects to index' do
        post :create, params: valid_params
        expect(response).to redirect_to(admin_resource_collection_path(resource: 'subjects'))
      end

      it 'generates slug automatically' do
        post :create, params: valid_params
        expect(Subject.last.slug).to eq('new-subject')
      end

      it 'assigns order_index automatically' do
        post :create, params: valid_params
        expect(Subject.last.order_index).to be_present
      end
    end
  end

  describe 'PATCH #update' do
    let(:subject_record) { create(:subject, title: 'Original Title') }

    context 'with valid params' do
      it 'updates the subject' do
        patch :update, params: { resource: 'subjects', id: subject_record.id, subject: { title: 'Updated Title' } }
        expect(subject_record.reload.title).to eq('Updated Title')
      end

      it 'redirects to index' do
        patch :update, params: { resource: 'subjects', id: subject_record.id, subject: { title: 'Updated Title' } }
        expect(response).to redirect_to(admin_resource_collection_path(resource: 'subjects'))
      end
    end

    context 'with slug update' do
      it 'updates the slug' do
        patch :update, params: { resource: 'subjects', id: subject_record.id, subject: { slug: 'new-slug' } }
        expect(subject_record.reload.slug).to eq('new-slug')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'for subject without dependencies' do
      let!(:subject_record) { create(:subject) }

      it 'destroys the subject' do
        expect do
          delete :destroy, params: { resource: 'subjects', id: subject_record.id }
        end.to change(Subject, :count).by(-1)
      end

      it 'redirects to index' do
        delete :destroy, params: { resource: 'subjects', id: subject_record.id }
        expect(response).to redirect_to(admin_resource_collection_path(resource: 'subjects'))
      end
    end

    context 'for subject with units' do
      let!(:subject_record) { create(:subject) }
      let!(:unit) { create(:unit, subject: subject_record) }

      it 'destroys subject with cascade delete of units' do
        expect do
          delete :destroy, params: { resource: 'subjects', id: subject_record.id }
        end.to change(Subject, :count).by(-1).and change(Unit, :count).by(-1)
      end
    end
  end

  describe 'POST #reorder_learning_module_contents' do
    let(:subject_record) { create(:subject) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit) }
    let!(:content1) { create(:content, learning_module: learning_module, order_index: 1) }
    let!(:content2) { create(:content, learning_module: learning_module, order_index: 2) }

    it 'reorders contents' do
      post :reorder_learning_module_contents,
           params: { id: learning_module.id, content_ids: [content2.id, content1.id] }
      expect(response).to have_http_status(:ok)
    end

    it 'returns bad_request for invalid content_ids' do
      post :reorder_learning_module_contents,
           params: { id: learning_module.id, content_ids: 'invalid' }
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns bad_request for content not belonging to module' do
      other_module = create(:learning_module, unit: unit)
      other_content = create(:content, learning_module: other_module)
      post :reorder_learning_module_contents,
           params: { id: learning_module.id, content_ids: [other_content.id] }
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

  describe 'GET #index for other resources' do
    it 'loads users (headmasters)' do
      get :index, params: { resource: 'users' }
      expect(response).to have_http_status(:ok)
    end

    it 'loads teachers' do
      get :index, params: { resource: 'teachers' }
      expect(response).to have_http_status(:ok)
    end

    it 'loads students' do
      get :index, params: { resource: 'students' }
      expect(response).to have_http_status(:ok)
    end

    it 'loads events' do
      get :index, params: { resource: 'events' }
      expect(response).to have_http_status(:ok)
    end

    it 'loads units' do
      get :index, params: { resource: 'units' }
      expect(response).to have_http_status(:ok)
    end

    it 'loads learning_modules' do
      get :index, params: { resource: 'learning_modules' }
      expect(response).to have_http_status(:ok)
    end

    it 'loads contents' do
      get :index, params: { resource: 'contents' }
      expect(response).to have_http_status(:ok)
    end
  end
end
