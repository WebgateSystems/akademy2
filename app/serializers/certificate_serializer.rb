class CertificateSerializer < ApplicationSerializer
  attributes :id, :certificate_number, :issued_at

  attribute :pdf_url do |obj|
    obj.pdf.url
  end
end
