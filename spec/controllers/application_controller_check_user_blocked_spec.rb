# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, '#check_user_blocked' do
  controller do
    def index
      render plain: 'OK'
    end
  end

  let(:user) { create(:user, confirmed_at: Time.current) }

  before do
    sign_in user
  end

  it 'allows access when no user-block rule exists' do
    get :index
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('OK')
  end

  it 'signs out and redirects when user is blocked by RequestBlockRule(user)' do
    RequestBlockRule.create!(rule_type: 'user', value: user.id)

    get :index

    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to be_present

    # `current_user` can be memoized in controller specs; assert via warden/session instead.
    expect(controller.request.env['warden']&.user).to be_nil
  end
end
