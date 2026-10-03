# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'rspec'
require_relative '../app'

# Safety: specs must run against paywithruby_test, never dev.
if ENV['DATABASE_URL_TEST'].nil? || ENV['DATABASE_URL_TEST'].empty?
  raise 'DATABASE_URL_TEST is missing. Copy .env.example to .env and set it.'
end

if ENV['DATABASE_URL_TEST'] == ENV['DATABASE_URL']
  raise 'DATABASE_URL_TEST must differ from DATABASE_URL (test isolation).'
end

raise 'DB not connected in test env' if DB.nil?

RSpec.configure do |config|
  config.include Rack::Test::Methods

  # Roll back each example so tests never leak rows into paywithruby_test.
  config.around(:each) do |example|
    DB.transaction(rollback: :always, auto_savepoint: true) do
      example.run
    end
  end
end

def app
  App
end
