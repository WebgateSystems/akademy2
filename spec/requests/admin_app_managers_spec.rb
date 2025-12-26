# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin: app managers', type: :request do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let!(:manager_role) { Role.find_or_create_by!(key: 'manager') { |r| r.name = 'Manager' } }
  let(:admin_user) do
    user = create(:user)
    UserRole.create!(user: user, role: admin_role)
    user
  end

  before do
    admin_user
    # Request specs do not have easy access to the custom /admin session cookie.
    # Follow existing spec convention: stub current_admin on Admin::BaseController.
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin_user)
    # rubocop:enable RSpec/AnyInstance
  end

  it 'renders app managers index' do
    get admin_resource_collection_path(resource: 'app_managers')
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Managerzy aplikacji')
  end

  it 'creates an app manager with manager role and confirms it' do
    post admin_create_resource_path(resource: 'app_managers'), params: {
      user: {
        role_key: 'manager',
        email: 'app.manager@example.com',
        password: 'Password123!',
        password_confirmation: 'Password123!'
      }
    }

    expect(response).to have_http_status(:found)
    created = User.find_by(email: 'app.manager@example.com')
    expect(created).to be_present
    expect(created.manager?).to be(true)
    expect(created.confirmed_at).to be_present
  end

  it 'updates an app manager' do
    manager = create(:user, email: 'edit.manager@example.com', confirmed_at: Time.current)
    UserRole.create!(user: manager, role: manager_role)

    patch admin_update_resource_path(resource: 'app_managers', id: manager.id), params: {
      user: {
        first_name: 'Nowe',
        last_name: 'Nazwisko'
      }
    }

    expect(response).to have_http_status(:found)
    expect(manager.reload.first_name).to eq('Nowe')
    expect(manager.reload.last_name).to eq('Nazwisko')
  end

  it 'locks and unlocks an app manager account' do
    manager = create(:user, email: 'locked.manager@example.com')
    UserRole.create!(user: manager, role: manager_role)

    post admin_lock_resource_path(resource: 'app_managers', id: manager.id)
    expect(response).to have_http_status(:found)
    expect(manager.reload.locked_at).to be_present

    post admin_unlock_resource_path(resource: 'app_managers', id: manager.id)
    expect(response).to have_http_status(:found)
    expect(manager.reload.locked_at).to be_nil
  end

  it 'destroys an app manager' do
    manager = create(:user, email: 'destroy.manager@example.com', confirmed_at: Time.current)
    UserRole.create!(user: manager, role: manager_role)

    delete admin_destroy_resource_path(resource: 'app_managers', id: manager.id)

    expect(response).to have_http_status(:found)
    expect(User.find_by(id: manager.id)).to be_nil
  end
end
