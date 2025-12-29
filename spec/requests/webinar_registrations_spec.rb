# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WebinarRegistrations' do
  describe 'POST /webinar_registrations' do
    let(:valid_params) do
      {
        webinar_registration: {
          first_name: 'Jan',
          last_name: 'Kowalski',
          email: 'jan.kowalski@szkola.edu.pl',
          position: 'Dyrektor',
          school_name: 'SP nr 1 w Warszawie',
          phone: '+48 123 456 789'
        }
      }
    end

    context 'with valid params' do
      before { allow(SendEmailJob).to receive(:enqueue) }

      it 'creates a new registration' do
        expect { post webinar_registrations_path, params: valid_params, as: :json }
          .to change(WebinarRegistration, :count).by(1)
      end

      it 'returns success response' do
        post webinar_registrations_path, params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['success']).to be true
        expect(json['message']).to include('Dziękujemy za rejestrację')
      end

      it 'stores all provided fields' do
        post webinar_registrations_path, params: valid_params, as: :json

        registration = WebinarRegistration.last
        expect(registration.first_name).to eq('Jan')
        expect(registration.last_name).to eq('Kowalski')
        expect(registration.email).to eq('jan.kowalski@szkola.edu.pl')
        expect(registration.position).to eq('Dyrektor')
        expect(registration.school_name).to eq('SP nr 1 w Warszawie')
        expect(registration.phone).to eq('+48 123 456 789')
        expect(registration.webinar_id).to eq('2025-12-29-akademy-intro')
      end

      it 'stores IP address and user agent' do
        post webinar_registrations_path,
             params: valid_params,
             headers: { 'User-Agent' => 'TestBrowser/1.0' },
             as: :json

        registration = WebinarRegistration.last
        expect(registration.ip_address).to be_present
        expect(registration.user_agent).to eq('TestBrowser/1.0')
      end

      it 'sends confirmation email' do
        post webinar_registrations_path, params: valid_params, as: :json

        expect(SendEmailJob).to have_received(:enqueue)
          .with('WebinarMailer', 'registration_confirmation', instance_of(WebinarRegistration))
      end
    end

    context 'with minimal required params' do
      let(:minimal_params) do
        {
          webinar_registration: {
            first_name: 'Anna',
            last_name: 'Nowak',
            email: 'anna@example.com'
          }
        }
      end

      before { allow(SendEmailJob).to receive(:enqueue) }

      it 'creates registration with only required fields' do
        expect { post webinar_registrations_path, params: minimal_params, as: :json }
          .to change(WebinarRegistration, :count).by(1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid params' do
      it 'returns error for missing first_name' do
        params = valid_params.deep_dup
        params[:webinar_registration].delete(:first_name)

        post webinar_registrations_path, params: params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['success']).to be false
        expect(json['errors']).to be_present
      end

      it 'returns error for missing email' do
        params = valid_params.deep_dup
        params[:webinar_registration].delete(:email)

        post webinar_registrations_path, params: params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for invalid email format' do
        params = valid_params.deep_dup
        params[:webinar_registration][:email] = 'not-an-email'

        post webinar_registrations_path, params: params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['errors']).to include(match(/Email/i))
      end
    end

    context 'with duplicate registration' do
      before do
        allow(SendEmailJob).to receive(:enqueue)
        create(:webinar_registration,
               email: 'jan.kowalski@szkola.edu.pl',
               webinar_id: '2025-12-29-akademy-intro')
      end

      it 'returns error for duplicate email in same webinar' do
        post webinar_registrations_path, params: valid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['success']).to be false
        expect(json['errors']).to include(match(/już zapisano/i))
      end
    end
  end
end
