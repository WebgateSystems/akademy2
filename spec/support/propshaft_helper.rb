# frozen_string_literal: true

# Helper to stub Propshaft asset resolution in tests
# This prevents errors when assets are not compiled in CI/test environment
RSpec.configure do |config|
  config.before(:each, type: :request) do
    # Stub asset helpers to return empty strings or placeholder paths
    # This prevents Propshaft::MissingAssetError when assets are not compiled
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ActionView::Base).to receive(:stylesheet_link_tag).and_return('')
    allow_any_instance_of(ActionView::Base).to receive(:javascript_include_tag).and_return('')
    # rubocop:enable RSpec/AnyInstance
  end
end
