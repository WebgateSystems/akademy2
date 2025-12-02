# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: 'OK'
    end
  end

  describe 'Pundit authorization error handling' do
    before do
      routes.draw { get 'index' => 'anonymous#index' }
    end

    context 'when Pundit::NotAuthorizedError is raised' do
      before do
        allow(controller).to receive(:index).and_raise(Pundit::NotAuthorizedError)
      end

      context 'when admin_root_path is available' do
        before do
          allow(controller).to receive(:respond_to?).and_call_original
          allow(controller).to receive(:respond_to?).with(:admin_root_path, any_args).and_return(true)
          allow(controller).to receive(:admin_root_path).and_return('/admin')
        end

        it 'redirects to admin_root_path' do
          get :index
          expect(response).to redirect_to('/admin')
          expect(flash[:alert]).to eq('Brak uprawnień.')
        end

        it 'uses referer if available' do
          request.env['HTTP_REFERER'] = '/previous_page'
          get :index
          expect(response).to redirect_to('/previous_page')
        end
      end

      context 'when admin_root_path is not available' do
        before do
          allow(controller).to receive(:respond_to?).and_call_original
          allow(controller).to receive(:respond_to?).with(:admin_root_path, any_args).and_return(false)
          allow(controller).to receive(:respond_to?).with(:new_user_session_path, any_args).and_return(true)
          allow(controller).to receive(:new_user_session_path).and_return('/users/sign_in')
        end

        it 'redirects to new_user_session_path' do
          get :index
          expect(response).to redirect_to('/users/sign_in')
          expect(flash[:alert]).to eq('Brak uprawnień.')
        end
      end

      context 'when neither path is available' do
        before do
          allow(controller).to receive(:respond_to?).and_call_original
          allow(controller).to receive(:respond_to?).with(:admin_root_path, any_args).and_return(false)
          allow(controller).to receive(:respond_to?).with(:new_user_session_path, any_args).and_return(false)
        end

        it 'redirects to referer when available' do
          # Set referer to a relative path (safe)
          request.env['HTTP_REFERER'] = '/safe_path'
          get :index
          expect(response).to redirect_to('/safe_path')
          expect(flash[:alert]).to eq('Brak uprawnień.')
        end

        it 'raises error when fallback is unsafe' do
          # When referer is nil and fallback is 'up', Rails blocks unsafe redirect
          request.env['HTTP_REFERER'] = nil
          expect { get :index }.to raise_error(ActionController::Redirecting::OpenRedirectError)
        end
      end
    end
  end

  describe '#after_sign_in_path_for' do
    let(:principal_role) { Role.find_or_create_by!(key: 'principal') { |r| r.name = 'Principal' } }
    let(:school_manager_role) { Role.find_or_create_by!(key: 'school_manager') { |r| r.name = 'School Manager' } }
    let(:teacher_role) { Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' } }
    let(:school) { create(:school) }

    before do
      principal_role
      school_manager_role
      teacher_role
    end

    context 'when user is not a User instance' do
      let(:non_user_resource) { double('NonUserResource') }

      it 'does not execute User-specific logic' do
        # For non-User instances, after_sign_in_path_for should delegate to Devise's implementation (super)
        # Devise raises if resource class has no mapping, so we focus on ensuring
        # that the User-specific branch (roles lookup) is not executed.

        allow(non_user_resource).to receive(:is_a?).with(User).and_return(false)
        expect(non_user_resource).not_to receive(:roles)

        expect do
          controller.after_sign_in_path_for(non_user_resource)
        end.to raise_error(RuntimeError, /Could not find a valid mapping/)
      end
    end

    context 'when user has principal role' do
      let(:user) do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: principal_role, school: school)
        u.reload
      end

      it 'redirects to management_root_path' do
        expect(controller.after_sign_in_path_for(user)).to eq(management_root_path)
      end
    end

    context 'when user has school_manager role' do
      let(:user) do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: school_manager_role, school: school)
        u.reload
      end

      it 'redirects to management_root_path' do
        expect(controller.after_sign_in_path_for(user)).to eq(management_root_path)
      end
    end

    context 'when user has teacher role' do
      let(:user) do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: teacher_role, school: school)
        u.reload
      end

      it 'redirects to authenticated_root_path' do
        expect(controller.after_sign_in_path_for(user)).to eq(authenticated_root_path)
      end
    end

    context 'when user has no management roles' do
      let(:user) do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: teacher_role, school: school)
        u.reload
      end

      it 'redirects to authenticated_root_path' do
        expect(controller.after_sign_in_path_for(user)).to eq(authenticated_root_path)
      end
    end
  end
end
