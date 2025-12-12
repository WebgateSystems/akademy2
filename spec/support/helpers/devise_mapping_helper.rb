# frozen_string_literal: true

module DeviseMappingHelper
  def with_devise_mapping(mapping = Devise.mappings[:user])
    # This helper is used in request specs to set devise.mapping
    # It modifies the request env before the request is made
    return yield unless defined?(request) && request

    original_env = request.env.dup
    request.env['devise.mapping'] = mapping
    yield
  ensure
    if defined?(request) && request
      request.env.delete('devise.mapping')
      request.env.merge!(original_env) if original_env
    end
  end
end

RSpec.configure do |config|
  config.include DeviseMappingHelper, type: :request
end
