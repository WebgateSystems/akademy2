module Auth
  class AuthStrategyResolver
    STRATEGIES = [
      Auth::Strategies::EmailAuthStrategy,
      Auth::Strategies::PhoneAuthStrategy
    ].freeze

    def self.resolve(params)
      STRATEGIES
        .map { |klass| klass.new(params) }
        .find(&:valid?)
    end
  end
end
