# frozen_string_literal: true

# Hand-written input validation for auth (no DB, no HTTP).
# Returns { ok: bool, errors: hash }. Controllers map errors to 422.

module AuthValidator
  ALLOWED_SIGNUP = %w[email password role].freeze
  ROLES = %w[rider driver].freeze
  EMAIL_RE = /\A[^@\s]+@[^@\s]+\z/
  MAX = { 'email' => 255, 'password' => 72, 'role' => 20 }.freeze
  MIN_PASSWORD = 8

  def self.validate_signup(attrs)
    errors = {}
    unknown = attrs.keys.map(&:to_s) - ALLOWED_SIGNUP
    errors[:base] = "unknown attributes: #{unknown.join(', ')}" unless unknown.empty?

    email = attrs[:email] || attrs['email']
    errors[:email] = 'is required' if blank?(email)
    errors[:email] = 'is not a valid email' if !blank?(email) && email !~ EMAIL_RE

    password = attrs[:password] || attrs['password']
    errors[:password] = 'is required' if blank?(password)
    if !blank?(password)
      errors[:password] = "is too short (minimum #{MIN_PASSWORD} characters)" if password.to_s.length < MIN_PASSWORD
    end

    role = attrs[:role] || attrs['role']
    errors[:role] = "must be one of: #{ROLES.join(', ')}" if !blank?(role) && !ROLES.include?(role.to_s)

    check_lengths(attrs, errors, ALLOWED_SIGNUP)

    { ok: errors.empty?, errors: errors }
  end

  def self.validate_login(attrs)
    errors = {}
    email = attrs[:email] || attrs['email']
    password = attrs[:password] || attrs['password']
    errors[:email] = 'is required' if blank?(email)
    errors[:password] = 'is required' if blank?(password)

    { ok: errors.empty?, errors: errors }
  end

  def self.check_lengths(attrs, errors, keys)
    keys.map(&:to_s).each do |key|
      next unless MAX.key?(key)

      value = attrs[key.to_sym] || attrs[key]
      next if blank?(value)
      next unless value.to_s.length > MAX[key]

      errors[key.to_sym] ||= "is too long (maximum #{MAX[key]} characters)"
    end
  end

  def self.blank?(value)
    value.nil? || value.to_s.strip.empty?
  end
end
