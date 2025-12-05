# frozen_string_literal: true

Mjml.setup do |config|
  # Use mrml (Rust implementation) - faster and no Node.js required
  config.use_mrml = true
end
