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
        created_subject = Subject.find_by(title: 'New Subject')
        expect(created_subject.slug).to eq('new-subject')
      end

      it 'assigns order_index automatically' do
        post :create, params: valid_params
        created_subject = Subject.find_by(title: 'New Subject')
        expect(created_subject.order_index).to be_present
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

  describe 'GET #show for other resources' do
    let(:subject_record) { create(:subject) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit) }
    let(:content) { create(:content, learning_module: learning_module) }

    it 'shows unit' do
      get :show, params: { resource: 'units', id: unit.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('admin/resources/units_show')
    end

    it 'shows learning_module' do
      get :show, params: { resource: 'learning_modules', id: learning_module.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('admin/resources/learning_modules_show')
    end

    it 'shows content' do
      get :show, params: { resource: 'contents', id: content.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('admin/resources/contents_show')
    end
  end

  describe 'GET #new for other resources' do
    it 'new unit' do
      get :new, params: { resource: 'units' }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('admin/resources/units_new')
    end

    it 'new learning_module' do
      get :new, params: { resource: 'learning_modules' }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('admin/resources/learning_modules_new')
    end

    it 'new content' do
      get :new, params: { resource: 'contents' }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('admin/resources/contents_new')
    end

    it 'new school' do
      get :new, params: { resource: 'schools' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #edit for other resources' do
    let(:subject_record) { create(:subject) }
    let(:unit) { create(:unit, subject: subject_record) }
    let(:learning_module) { create(:learning_module, unit: unit) }
    let(:content) { create(:content, learning_module: learning_module) }

    it 'edits unit' do
      get :edit, params: { resource: 'units', id: unit.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('admin/resources/units_edit')
    end

    it 'edits learning_module' do
      get :edit, params: { resource: 'learning_modules', id: learning_module.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('admin/resources/learning_modules_edit')
    end

    it 'edits content' do
      get :edit, params: { resource: 'contents', id: content.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('admin/resources/contents_edit')
    end
  end

  describe 'POST #create for other resources' do
    context 'for unit' do
      let(:subject_record) { create(:subject) }

      it 'creates a unit' do
        expect do
          post :create, params: { resource: 'units', unit: { title: 'New Unit', subject_id: subject_record.id } }
        end.to change(Unit, :count).by(1)
      end

      it 'sets order_index automatically' do
        post :create, params: { resource: 'units', unit: { title: 'New Unit', subject_id: subject_record.id } }
        created_unit = Unit.find_by(title: 'New Unit')
        expect(created_unit.order_index).to be_present
      end
    end

    context 'for learning_module' do
      let(:subject_record) { create(:subject) }
      let(:unit) { create(:unit, subject: subject_record) }

      it 'creates a learning_module' do
        expect do
          post :create,
               params: { resource: 'learning_modules', learning_module: { title: 'New Module', unit_id: unit.id } }
        end.to change(LearningModule, :count).by(1)
      end

      it 'sets order_index automatically' do
        post :create,
             params: { resource: 'learning_modules', learning_module: { title: 'New Module', unit_id: unit.id } }
        created_module = LearningModule.find_by(title: 'New Module')
        expect(created_module.order_index).to be_present
      end
    end

    context 'for content' do
      let(:subject_record) { create(:subject) }
      let(:unit) { create(:unit, subject: subject_record) }
      let(:learning_module) { create(:learning_module, unit: unit) }

      it 'creates a content' do
        expect do
          post :create, params: {
            resource: 'contents',
            content: { title: 'New Content', learning_module_id: learning_module.id, content_type: 'video' }
          }
        end.to change(Content, :count).by(1)
      end

      it 'sets order_index automatically' do
        post :create, params: {
          resource: 'contents',
          content: { title: 'New Content', learning_module_id: learning_module.id, content_type: 'video' }
        }
        created_content = Content.find_by(title: 'New Content')
        expect(created_content.order_index).to be_present
      end
    end

    context 'for school' do
      it 'creates a school' do
        expect do
          post :create, params: { resource: 'schools', school: { name: 'New School', city: 'Warsaw' } }
        end.to change(School, :count).by(1)
      end

      it 'generates slug automatically' do
        post :create, params: { resource: 'schools', school: { name: 'New School', city: 'Warsaw' } }
        created_school = School.find_by(name: 'New School')
        expect(created_school.slug).to eq('new-school')
      end
    end

    context 'for headmaster' do
      let(:school) { create(:school) }
      let!(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }

      it 'creates a user with principal role' do
        expect do
          post :create, params: {
            resource: 'users',
            user: {
              email: 'headmaster@example.com',
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'Head',
              last_name: 'Master',
              school_id: school.id,
              role_key: 'principal'
            }
          }
        end.to change(User, :count).by(1)
      end
    end
  end

  describe 'PATCH #update for other resources' do
    context 'for unit' do
      let(:subject_record) { create(:subject) }
      let(:unit) { create(:unit, subject: subject_record, title: 'Original') }

      it 'updates the unit' do
        patch :update, params: { resource: 'units', id: unit.id, unit: { title: 'Updated' } }
        expect(unit.reload.title).to eq('Updated')
      end
    end

    context 'for learning_module' do
      let(:subject_record) { create(:subject) }
      let(:unit) { create(:unit, subject: subject_record) }
      let(:learning_module) { create(:learning_module, unit: unit, title: 'Original') }

      it 'updates the learning_module' do
        patch :update,
              params: { resource: 'learning_modules', id: learning_module.id, learning_module: { title: 'Updated' } }
        expect(learning_module.reload.title).to eq('Updated')
      end
    end

    context 'for content' do
      let(:subject_record) { create(:subject) }
      let(:unit) { create(:unit, subject: subject_record) }
      let(:learning_module) { create(:learning_module, unit: unit) }
      let(:content) { create(:content, learning_module: learning_module, title: 'Original') }

      it 'updates the content' do
        patch :update, params: { resource: 'contents', id: content.id, content: { title: 'Updated' } }
        expect(content.reload.title).to eq('Updated')
      end

      it 'handles payload_json for quiz' do
        content.update!(content_type: 'quiz')
        quiz_payload = { questions: [{ text: 'Question 1' }] }.to_json
        patch :update, params: { resource: 'contents', id: content.id, content: { payload_json: quiz_payload } }
        expect(content.reload.payload).to eq({ 'questions' => [{ 'text' => 'Question 1' }] })
      end

      it 'handles payload_subtitles_lang for video' do
        content.update!(content_type: 'video')
        patch :update, params: { resource: 'contents', id: content.id, content: { payload_subtitles_lang: 'pl' } }
        expect(content.reload.payload).to eq({ 'subtitles_lang' => 'pl' })
      end
    end

    context 'for school' do
      let(:school) { create(:school, name: 'Original School') }

      it 'updates the school' do
        patch :update, params: { resource: 'schools', id: school.id, school: { name: 'Updated School' } }
        expect(school.reload.name).to eq('Updated School')
      end

      it 'generates slug if blank and name is present' do
        school.update!(slug: nil)
        patch :update, params: { resource: 'schools', id: school.id, school: { name: 'New Name', slug: '' } }
        expect(school.reload.slug).to eq('new-name')
      end
    end

    context 'for subject icon removal' do
      let(:subject_record) { create(:subject) }

      it 'removes icon when requested' do
        allow_any_instance_of(Subject).to receive(:remove_icon!)
        patch :update,
              params: { resource: 'subjects', id: subject_record.id, subject: { title: 'Updated', remove_icon: '1' } }
        expect(response).to redirect_to(admin_resource_collection_path(resource: 'subjects'))
      end
    end
  end

  describe 'DELETE #destroy for other resources' do
    context 'for unit' do
      let(:subject_record) { create(:subject) }
      let!(:unit) { create(:unit, subject: subject_record) }

      it 'destroys the unit' do
        expect do
          delete :destroy, params: { resource: 'units', id: unit.id }
        end.to change(Unit, :count).by(-1)
      end
    end

    context 'for learning_module' do
      let(:subject_record) { create(:subject) }
      let(:unit) { create(:unit, subject: subject_record) }
      let!(:learning_module) { create(:learning_module, unit: unit) }

      it 'destroys the learning_module' do
        expect do
          delete :destroy, params: { resource: 'learning_modules', id: learning_module.id }
        end.to change(LearningModule, :count).by(-1)
      end
    end

    context 'for content' do
      let(:subject_record) { create(:subject) }
      let(:unit) { create(:unit, subject: subject_record) }
      let(:learning_module) { create(:learning_module, unit: unit) }
      let!(:content) { create(:content, learning_module: learning_module) }

      it 'destroys the content' do
        expect do
          delete :destroy, params: { resource: 'contents', id: content.id }
        end.to change(Content, :count).by(-1)
      end
    end

    context 'for school' do
      let!(:school) { create(:school) }

      it 'destroys the school' do
        expect do
          delete :destroy, params: { resource: 'schools', id: school.id }
        end.to change(School, :count).by(-1)
      end
    end
  end

  describe 'check_blocking_associations' do
    let(:controller_instance) { described_class.new }

    context 'for Subject' do
      let(:subject_record) { create(:subject) }

      before do
        controller_instance.instance_variable_set(:@resource_class, Subject)
        controller_instance.instance_variable_set(:@record, subject_record)
      end

      it 'returns nil when no blocking associations' do
        result = controller_instance.check_blocking_associations
        expect(result).to be_nil
      end
    end

    context 'for Unit' do
      let(:subject_record) { create(:subject) }
      let(:unit) { create(:unit, subject: subject_record) }

      before do
        controller_instance.instance_variable_set(:@resource_class, Unit)
        controller_instance.instance_variable_set(:@record, unit)
      end

      it 'returns nil when no blocking associations' do
        result = controller_instance.check_blocking_associations
        expect(result).to be_nil
      end
    end

    context 'for LearningModule' do
      let(:subject_record) { create(:subject) }
      let(:unit) { create(:unit, subject: subject_record) }
      let(:learning_module) { create(:learning_module, unit: unit) }

      before do
        controller_instance.instance_variable_set(:@resource_class, LearningModule)
        controller_instance.instance_variable_set(:@record, learning_module)
      end

      it 'returns nil when no blocking associations' do
        result = controller_instance.check_blocking_associations
        expect(result).to be_nil
      end
    end
  end
end
