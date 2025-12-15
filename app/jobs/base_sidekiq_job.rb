class BaseSidekiqJob
  include Sidekiq::Job

  # Default queue and retry strategy for Sidekiq jobs
  sidekiq_options queue: :default, retry: 5

  # Quadratic backoff similar to ActiveJob's polynomially_longer
  sidekiq_retry_in do |count|
    (count**2) * 60 # 1m, 4m, 9m, 16m, 25m
  end
end
