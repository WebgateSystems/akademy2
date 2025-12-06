# frozen_string_literal: true

# Elasticsearch/Searchkick configuration
# ES 8.8.1 running in Docker on port 9200 (shared instance for multiple projects)
#
# Configuration via config/settings.yml:
#   elasticsearch.url - connection URL (default: http://localhost:9200)
#   elasticsearch.index_prefix - prefix for indices (default: akademy2)
#   elasticsearch.enabled - enable/disable ES (default: true, false in test)
#
# Index naming convention:
#   {prefix}_{environment}_{model_name}
#   Example: akademy2_production_student_videos

# Index prefix to distinguish this app's indices from other projects
index_prefix = Settings.elasticsearch&.index_prefix || 'akademy2'
Searchkick.index_prefix = "#{index_prefix}_#{Rails.env}"

# Check if ES is enabled (disabled by default in test environment)
es_enabled = if Settings.elasticsearch&.enabled.nil?
               !Rails.env.test?
             else
               Settings.elasticsearch.enabled
             end

# Elasticsearch connection URL
elasticsearch_url = Settings.elasticsearch&.url || 'http://localhost:9200'

# Configure Elasticsearch client only if enabled
if es_enabled
  begin
    Searchkick.client = Elasticsearch::Client.new(
      url: elasticsearch_url,
      retry_on_failure: 3,
      request_timeout: 15,
      log: Rails.env.development?
    )
  rescue StandardError => e
    Rails.logger.warn "[Elasticsearch] Failed to configure client: #{e.message}"
    Rails.logger.warn '[Elasticsearch] Search features will use database fallback'
  end
end
# When ES is not enabled (e.g., in test environment):
# Searchkick.callbacks= is deprecated in newer versions
# Callbacks are automatically disabled when Searchkick.client is nil
# No action needed - Searchkick will skip indexing when client is nil

# Queue for async reindexing (uses Sidekiq)
Searchkick.queue_name = :searchkick

# Log configuration at startup
Rails.logger.info "[Elasticsearch] Enabled: #{es_enabled}"
Rails.logger.info "[Elasticsearch] URL: #{elasticsearch_url}" if es_enabled
Rails.logger.info "[Elasticsearch] Index prefix: #{Searchkick.index_prefix}"
