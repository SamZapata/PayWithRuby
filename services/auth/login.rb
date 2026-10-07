# frozen_string_literal: true

require 'bcrypt'

# Business operation: verify credentials and issue a JWT.
# Returns { user:, token: } on success, nil on bad credentials/inactive.

module Auth
  class Login
    def self.call(email, password)
      user = UserRepository.find_by_email(email)
      return nil if user.nil?
      return nil unless user.status == 'active'
      return nil if user.password_hash.nil? || user.password_hash.empty?

      begin
        valid = BCrypt::Password.new(user.password_hash) == password.to_s
      rescue BCrypt::Errors::InvalidHash
        return nil
      end
      return nil unless valid

      { user: user, token: Tokens.encode(user_id: user.id, role: user.role) }
    end
  end
end
