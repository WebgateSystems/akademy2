require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/app/models'
  add_filter '/app/jobs'
  add_filter '/app/mailers'
  add_filter '/lib'
  add_filter 'app/channels/application_cable/connection.rb'
  add_filter 'app/dashboards'
  add_filter 'app/controllers/admin'

  minimum_coverage(50)
end
