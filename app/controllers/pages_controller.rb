# frozen_string_literal: true

class PagesController < ApplicationController
  layout false

  def privacy_policy
    # No authentication required - public page
  end

  def accessibility
    # No authentication required - public page
  end

  def license
    # No authentication required - public page
  end
end
