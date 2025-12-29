# frozen_string_literal: true

class WebinarRegistrationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  skip_before_action :check_user_active, only: [:create]
  skip_before_action :check_redirect_loop, only: [:create]

  CURRENT_WEBINAR_ID = '2025-12-29-akademy-intro'

  # POST /webinar_registrations
  def create
    @registration = WebinarRegistration.new(registration_params)
    @registration.webinar_id = CURRENT_WEBINAR_ID
    @registration.ip_address = request.remote_ip
    @registration.user_agent = request.user_agent

    if @registration.save
      @registration.send_confirmation_email!
      # rubocop:disable I18n/GetText/DecorateString
      render json: { success: true,
                     message: 'Dziękujemy za rejestrację! Link do webinaru został wysłany na podany adres e-mail.' }
      # rubocop:enable I18n/GetText/DecorateString
    else
      render json: { success: false, errors: @registration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:webinar_registration).permit(
      :first_name,
      :last_name,
      :email,
      :position,
      :school_name,
      :phone
    )
  end
end
