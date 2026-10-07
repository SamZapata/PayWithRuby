# frozen_string_literal: true

require 'bcrypt'

# Business operation: register a new user.
# Hashes password with bcrypt, never stores plain text.

module Auth
  class Signup
    def self.call(attrs)
      normalized = {
        email: (attrs[:email] || attrs['email']).to_s.strip.downcase,
        role: (attrs[:role] || attrs['role'] || 'rider').to_s,
        password_hash: BCrypt::Password.create(attrs[:password] || attrs['password']).to_s,
        status: 'active'
      }
      UserRepository.create(normalized)
    end
  end
end
