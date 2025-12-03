# frozen_string_literal: true

class AppIdService
  class << self
    def version
      @version ||= check_hash
    end

    private

    def check_hash
      if File.exist?('REVISION')
        File.read('REVISION').first(8)
      else
        `git rev-parse --short HEAD`.chomp
      end
    end
  end
end
