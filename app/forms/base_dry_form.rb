class BaseDryForm
  attr_reader :errors, :output

  def initialize(params = {})
    @params = params.to_h
    @result = contract.call(@params)

    @errors = @result.errors.to_h
    @output = @result.to_h
  end

  def valid?
    errors.empty?
  end

  def messages
    errors.flat_map do |field, msgs|
      msgs.map do |msg|
        "#{humanize(field)} #{msg}"
      end
    end
  end

  private

  def contract
    self.class::Contract.new
  end

  def humanize(field)
    field.to_s.tr('_', ' ').capitalize
  end
end
