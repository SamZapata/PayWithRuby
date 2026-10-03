# frozen_string_literal: true

# Database connection (Sequel + PostgreSQL).
# P0: must NOT crash when DATABASE_URL is missing (health works without DB).
# P1+: models/repositories will use DB constant.

require 'sequel'

DB =
  begin
    if ENV['DATABASE_URL'] && !ENV['DATABASE_URL'].empty?
      Sequel.connect(ENV['DATABASE_URL'])
    else
      nil
    end
  rescue StandardError => e
    warn "[database] connection skipped: #{e.class}: #{e.message}"
    nil
  end
