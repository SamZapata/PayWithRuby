# frozen_string_literal: true

require 'jwt'

# JWT encode/decode. Single place for secret, algorithm and expiry.
# P2 default: HS256, 24h TTL.

module Auth
  module Tokens
    ALGORITHM = 'HS256'
    TTL_SECONDS = 24 * 60 * 60

    def self.secret
      ENV['JWT_SECRET']
    end

    def self.encode(user_id:, role:)
      raise 'JWT_SECRET is missing. Set it in .env (see .env.example).' if secret.nil? || secret.empty?

      payload = { user_id: user_id, role: role, exp: Time.now.to_i + TTL_SECONDS }
      JWT.encode(payload, secret, ALGORITHM)
    end

    # Returns payload hash on success, nil on invalid/expired/missing secret.
    def self.decode(token)
      return nil if token.nil? || token.to_s.strip.empty?
      return nil if secret.nil? || secret.empty?

      decoded = JWT.decode(token.to_s.strip, secret, true, algorithm: ALGORITHM)
      decoded.first
    rescue JWT::ExpiredSignature, JWT::DecodeError
      nil
    end
  end
end
