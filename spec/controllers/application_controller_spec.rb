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
    let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
    let(:school) { create(:school) }

    before do
      principal_role
      school_manager_role
      teacher_role
      admin_role
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

    context 'when stored location exists' do
      let(:user) { create(:user, school: school) }

      it 'redirects to stored location regardless of roles' do
        allow(controller).to receive(:stored_location_for).with(user).and_return('/dashboard')
        expect(controller.after_sign_in_path_for(user)).to eq('/dashboard')
      end

      it 'redirects to stored management location even if user is teacher' do
        u = create(:user, school: school)
        UserRole.create!(user: u, role: teacher_role, school: school)
        u.reload

        allow(controller).to receive(:stored_location_for).with(u).and_return('/management')
        expect(controller.after_sign_in_path_for(u)).to eq('/management')
      end

      it 'clears session return_to after using stored_location' do
        allow(controller).to receive(:stored_location_for).with(user).and_return('/dashboard')
        session[:return_to] = '/management'

        result = controller.after_sign_in_path_for(user)

        expect(result).to eq('/dashboard')
        expect(session[:return_to]).to be_nil
      end
    end

    context 'when session return_to exists (but no stored_location)' do
      let(:user) { create(:user, school: school) }

      before do
        allow(controller).to receive(:stored_location_for).with(user).and_return(nil)
        session[:return_to] = '/admin'
      end

      it 'redirects to session return_to' do
        expect(controller.after_sign_in_path_for(user)).to eq('/admin')
        expect(session[:return_to]).to be_nil
      end
    end

    context 'when no stored location exists' do
      before do
        allow(controller).to receive(:stored_location_for).and_return(nil)
      end

      context 'when user has principal role only (no teacher role)' do
        let(:user) do
          u = create(:user, school: school)
          UserRole.create!(user: u, role: principal_role, school: school)
          u.reload
        end

        it 'redirects to management_root_path' do
          expect(controller.after_sign_in_path_for(user)).to eq(management_root_path)
        end
      end

      context 'when user has school_manager role only (no teacher role)' do
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

        before do
          allow(controller).to receive(:stored_location_for).and_return(nil)
        end

        it 'redirects to dashboard_path (teacher dashboard)' do
          expect(controller.after_sign_in_path_for(user)).to eq(dashboard_path)
        end
      end

      context 'when user has admin role' do
        let(:user) do
          u = create(:user, school: school)
          UserRole.create!(user: u, role: admin_role, school: school)
          u.reload
        end

        it 'redirects to admin_root_path' do
          expect(controller.after_sign_in_path_for(user)).to eq(admin_root_path)
        end
      end

      context 'when user has no teacher or management roles' do
        let(:user) do
          create(:user, school: school)
        end

        it 'redirects to root_path (landing page)' do
          expect(controller.after_sign_in_path_for(user)).to eq(root_path)
        end
      end
    end
  end

  describe 'redirect loop detection' do
    let(:user) { create(:user) }

    before do
      routes.draw { get 'index' => 'anonymous#index' }
      sign_in user
    end

    context 'when user hits the same path 20 times after redirect' do
      before do
        session[:last_redirect_path] = '/index'
        session[:last_redirect_count] = 19 # One more will trigger the limit of 20
        session[:last_redirect_time] = Time.current.to_i
        allow(controller.request).to receive_messages(path: '/index', referer: 'http://test.host/index')
      end

      it 'detects redirect loop after 20 consecutive redirects' do
        allow(controller).to receive(:respond_to?).and_call_original
        allow(controller).to receive(:respond_to?).with(:new_user_session_path, any_args).and_return(true)
        allow(controller).to receive_messages(current_user: user, new_user_session_path: '/users/sign_in')

        expect(controller).to receive(:reset_session)
        # rubocop:disable Layout/LineLength
        expect(controller).to receive(:redirect_to).with('/users/sign_in',
                                                         alert: 'Brak odpowiednich uprawnień do tego panelu. Zaloguj się ponownie.')
        # rubocop:enable Layout/LineLength

        controller.send(:check_redirect_loop)
      end

      it 'increments redirect count and triggers redirect' do
        allow(controller).to receive(:respond_to?).and_call_original
        allow(controller).to receive(:respond_to?).with(:new_user_session_path, any_args).and_return(true)
        allow(controller).to receive_messages(current_user: user, new_user_session_path: '/users/sign_in')
        allow(controller).to receive(:redirect_to)

        controller.send(:check_redirect_loop)

        # After check_redirect_loop, count increments to 20, triggering handle_redirect_loop
        # which calls redirect_to
        expect(controller).to have_received(:redirect_to)
      end
    end

    context 'when user hits same path but not from redirect' do
      before do
        session[:last_redirect_path] = '/index'
        session[:last_redirect_count] = 1
        session[:last_redirect_time] = Time.current.to_i
        allow(controller.request).to receive_messages(path: '/index', referer: 'http://test.host/different')
      end

      it 'does not detect redirect loop (normal navigation)' do
        allow(controller).to receive(:current_user).and_return(user)

        expect(controller).not_to receive(:handle_redirect_loop)

        controller.send(:check_redirect_loop)

        # Should reset tracking since it's not a redirect (same path but different referer)
        # But then it stores current path at the end, so last_redirect_path will be '/index'
        # The important thing is that redirect_count is cleared
        expect(session[:last_redirect_count]).to be_nil
        # And last_redirect_path is set to current path (normal behavior)
        expect(session[:last_redirect_path]).to eq('/index')
      end
    end

    context 'when user hits same path first time after redirect' do
      before do
        session[:last_redirect_path] = '/index'
        session[:last_redirect_count] = 0
        session[:last_redirect_time] = Time.current.to_i
        allow(controller.request).to receive_messages(path: '/index', referer: 'http://test.host/index')
      end

      it 'does not detect redirect loop (only first redirect)' do
        allow(controller).to receive(:current_user).and_return(user)

        expect(controller).not_to receive(:handle_redirect_loop)

        controller.send(:check_redirect_loop)

        expect(session[:last_redirect_count]).to eq(1)
      end
    end

    context 'when user hits different paths' do
      before do
        session[:last_redirect_path] = '/previous'
        allow(controller.request).to receive(:path).and_return('/index')
      end

      it 'does not detect redirect loop' do
        allow(controller).to receive(:current_user).and_return(user)

        expect(controller).not_to receive(:handle_redirect_loop)

        controller.send(:check_redirect_loop)

        expect(session[:last_redirect_path]).to eq('/index')
      end
    end

    context 'when more than 5 seconds passed' do
      before do
        session[:last_redirect_path] = '/index'
        session[:last_redirect_count] = 1
        session[:last_redirect_time] = 10.seconds.ago.to_i
        allow(controller.request).to receive(:path).and_return('/index')
      end

      it 'resets redirect tracking' do
        allow(controller).to receive(:current_user).and_return(user)

        controller.send(:check_redirect_loop)

        expect(session[:last_redirect_path]).to eq('/index')
        expect(session[:last_redirect_count]).to be_nil
        expect(session[:last_redirect_time]).to be_present
      end
    end

    context 'when user is not signed in' do
      before do
        sign_out user
        session[:last_redirect_path] = '/index'
        allow(controller.request).to receive(:path).and_return('/index')
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'does not check for redirect loop' do
        expect(controller).not_to receive(:handle_redirect_loop)

        controller.send(:check_redirect_loop)
      end
    end

    context 'when path is a login page' do
      before do
        session[:last_redirect_path] = '/users/sign_in'
        allow(controller.request).to receive(:path).and_return('/users/sign_in')
      end

      it 'skips redirect loop check' do
        allow(controller).to receive(:current_user).and_return(user)

        expect(controller).not_to receive(:handle_redirect_loop)

        controller.send(:check_redirect_loop)
      end
    end

    context 'when path is an API endpoint' do
      before do
        session[:last_redirect_path] = '/api/v1/something'
        allow(controller.request).to receive(:path).and_return('/api/v1/something')
      end

      it 'skips redirect loop check' do
        allow(controller).to receive(:current_user).and_return(user)

        expect(controller).not_to receive(:handle_redirect_loop)

        controller.send(:check_redirect_loop)
      end
    end

    context 'when path is a static asset (SVG)' do
      before do
        session[:last_redirect_path] = '/management/qr_code.svg'
        allow(controller.request).to receive(:path).and_return('/management/qr_code.svg')
      end

      it 'skips redirect loop check' do
        allow(controller).to receive(:current_user).and_return(user)

        expect(controller).not_to receive(:handle_redirect_loop)

        controller.send(:check_redirect_loop)
      end
    end
  end
end
