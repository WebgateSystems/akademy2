# frozen_string_literal: true

class StoreRedirectController < ApplicationController
  skip_before_action :check_user_active
  skip_before_action :check_redirect_loop

  layout 'application'

  def show
    target = resolve_target_url

    if target.present?
      redirect_to target, allow_other_host: true
    else
      render :show, status: :ok
    end
  end

  private

  def resolve_target_url
    forced = params[:platform].to_s.downcase
    return google_play_url if forced == 'android'
    return app_store_url if forced == 'ios'

    ua = request.user_agent.to_s
    return google_play_url if ua.match?(/android/i)
    return app_store_url if ua.match?(/iphone|ipad|ipod/i)

    nil
  end

  def google_play_url
    Settings.stores.google_play.url
  end

  def app_store_url
    Settings.stores.app_store.url.presence
  end
end
