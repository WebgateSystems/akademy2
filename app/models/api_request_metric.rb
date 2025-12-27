# frozen_string_literal: true

class ApiRequestMetric < ApplicationRecord
  validates :bucket_start, presence: true, uniqueness: true
end
