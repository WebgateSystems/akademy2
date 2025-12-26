# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin panel access control', type: :request do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:manager_role) { Role.find_or_create_by!(key: 'manager') { |r| r.name = 'Manager' } }
  let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }

  it 'allows admin to access /admin resources' do
    admin = create(:user, confirmed_at: Time.current)
    UserRole.create!(user: admin, role: admin_role)

    allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    get admin_resource_collection_path(resource: 'app_managers')

    expect(response).to have_http_status(:ok)
  end

  it 'allows manager to access /admin resources' do
    manager = create(:user, confirmed_at: Time.current)
    UserRole.create!(user: manager, role: manager_role)

    allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(manager)
    get admin_resource_collection_path(resource: 'app_managers')

    expect(response).to have_http_status(:ok)
  end

  it 'rejects non-admin/non-manager' do
    teacher = create(:user, confirmed_at: Time.current)
    UserRole.create!(user: teacher, role: teacher_role)

    allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(teacher)
    get admin_resource_collection_path(resource: 'app_managers')

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(new_admin_session_path)
  end

  it 'kicks locked manager out of /admin' do
    manager = create(:user, confirmed_at: Time.current)
    UserRole.create!(user: manager, role: manager_role)
    manager.lock_access!

    allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(manager)
    get admin_resource_collection_path(resource: 'app_managers')

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(new_admin_session_path)
  end
end
