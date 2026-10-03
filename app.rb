require 'dotenv/load' if File.exist?(File.expand_path('.env', __dir__))
require 'sinatra/base'
require 'sinatra/json'
require 'sequel'
require 'json'

require_relative 'config/database'
require_relative 'config/wompi'

require_relative 'services/health/check_service'
require_relative 'serializers/health_serializer'
require_relative 'controllers/health_controller'

class App < Sinatra::Base
  set :show_exceptions, false

  before do
    content_type :json
  end

  error Sequel::Error do
    status 500
    { error: { code: 'database_error', message: 'Database error' } }.to_json
  end

  error StandardError do
    status 500
    { error: { code: 'internal_error', message: 'Internal server error' } }.to_json
  end
end

require_relative 'routes/health_routes'

# To run with rackup: `rackup -p 4567`
