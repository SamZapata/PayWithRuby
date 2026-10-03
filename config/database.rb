# frozen_string_literal: true

# Database connection (Sequel + PostgreSQL).
# Uses DATABASE_URL_TEST when RACK_ENV=test so specs never touch dev data.
# Falls back to DATABASE_URL otherwise. Nil-safe for health without DB.

require 'sequel'

def self.resolve_database_url
  if ENV['RACK_ENV'] == 'test' && ENV['DATABASE_URL_TEST'] && !ENV['DATABASE_URL_TEST'].empty?
    ENV['DATABASE_URL_TEST']
  else
    ENV['DATABASE_URL']
  end
end

DB =
  begin
    url = self.resolve_database_url
    if url && !url.empty?
      Sequel.connect(url)
    else
      nil
    end
  rescue StandardError => e
    warn "[database] connection skipped: #{e.class}: #{e.message}"
    nil
  end
