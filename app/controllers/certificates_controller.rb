# frozen_string_literal: true

# Public certificate controller - no authentication required
# Displays certificate details or serves the PDF
class CertificatesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:show]

  def show
    @certificate = Certificate.find_by(id: params[:id])
    return render_not_found unless @certificate

    respond_to do |format|
      format.html { render :show }
      format.pdf { serve_pdf }
    end
  end

  private

  def serve_pdf
    if @certificate.pdf&.path && File.exist?(@certificate.pdf.path)
      send_file @certificate.pdf.path,
                filename: "certificate-#{@certificate.id}.pdf",
                type: 'application/pdf',
                disposition: 'inline'
    else
      render_not_found
    end
  end

  def render_not_found
    render plain: 'Certificate not found', status: :not_found
  end
end
