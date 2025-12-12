# lib/multi_logger.rb

class MultiLogger
  def initialize(*loggers)
    @loggers = loggers
  end

  def add(severity, message = nil, progname = nil, &block)
    @loggers.each { |logger| logger.add(severity, message, progname, &block) }
  end

  def method_missing(method, *args, &block)
    @loggers.each { |logger| logger.send(method, *args, &block) }
  end

  def respond_to_missing?(method, include_private = false)
    @loggers.any? { |logger| logger.respond_to?(method, include_private) } || super
  end
end
