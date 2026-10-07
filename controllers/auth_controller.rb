# frozen_string_literal: true

# HTTP coordination for auth. Owns status codes.
# Flow: Validator -> Service -> Serializer. No SQL, no JWT internals.

class AuthController
  def self.signup(attrs)
    check = AuthValidator.validate_signup(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid signup', details: check[:errors] } }] unless check[:ok]

    begin
      user = Auth::Signup.call(attrs)
    rescue Sequel::UniqueConstraintViolation
      return [422, { error: { code: 'validation_error', message: 'Email already taken', details: { email: 'already taken' } } }]
    rescue Sequel::ValidationFailed => e
      return [422, { error: { code: 'validation_error', message: 'Invalid signup', details: { base: e.message } } }]
    end

    token = Auth::Tokens.encode(user_id: user.id, role: user.role)
    [201, { data: { user: UserSerializer.to_h(user), token: token } }]
  end

  def self.login(attrs)
    check = AuthValidator.validate_login(attrs)
    return [422, { error: { code: 'validation_error', message: 'Invalid login', details: check[:errors] } }] unless check[:ok]

    result = Auth::Login.call(attrs[:email] || attrs['email'], attrs[:password] || attrs['password'])
    return [401, { error: { code: 'unauthorized', message: 'Invalid credentials' } }] if result.nil?

    [200, { data: { user: UserSerializer.to_h(result[:user]), token: result[:token] } }]
  end
end
