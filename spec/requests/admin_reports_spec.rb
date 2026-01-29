# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin reports', type: :request do
  let(:admin_role) { Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' } }
  let(:admin) do
    user = create(:user, confirmed_at: Time.current)
    UserRole.create!(user: user, role: admin_role)
    user
  end

  before do
    allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
    allow_any_instance_of(Admin::BaseController).to receive(:require_admin!).and_return(true)
  end

  describe 'GET /admin/reports' do
    it 'returns success' do
      get admin_reports_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders report page with stats' do
      get admin_reports_path
      expect(response.body).to include(I18n.t('admin.reports.title'))
      expect(response.body).to include(I18n.t('admin.reports.generated_at', datetime: '').split('%').first)
    end

    it 'renders export dropdown when HTML' do
      get admin_reports_path
      expect(response.body).to include(I18n.t('admin.reports.export'))
      expect(response.body).to include(admin_export_reports_pdf_path)
    end
  end

  describe 'GET /admin/reports/export.pdf' do
    # Requires wkhtmltopdf to be installed (e.g. brew install wkhtmltopdf)
    it 'returns PDF with inline disposition' do
      get admin_export_reports_pdf_path
      expect(response).to have_http_status(:success)
      expect(response.media_type).to include('application/pdf')
      expect(response.body[0..3]).to eq('%PDF')
      expect(response.headers['Content-Disposition']).to include('inline')
    end
  end
end
