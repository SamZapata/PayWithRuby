# frozen_string_literal: true

# Domain model for users (auth identity, separate from riders/drivers).
# Table mapping + associations only. Input validation in validators/auth_validator.rb.

class User < Sequel::Model(:users)
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  def validate
    super
    validates_presence %i[email password_hash]
    validates_unique :email
    validates_format(/\A[^@\s]+@[^@\s]+\z/, :email, message: 'is not a valid email') if email
    validates_includes %w[rider driver], :role, message: 'must be rider or driver' unless role.nil?
    validates_includes %w[active inactive], :status, message: 'must be active or inactive' unless status.nil?
  end
end
