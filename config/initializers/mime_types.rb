# frozen_string_literal: true

# Register PDF MIME type for admin reports export (e.g. /admin/reports.pdf)
Mime::Type.register 'application/pdf', :pdf unless Mime::Type.lookup_by_extension(:pdf)
