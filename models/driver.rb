# frozen_string_literal: true

# Domain model for drivers. Table mapping + associations only.
# Input validation lives in validators/driver_validator.rb.

class Driver < Sequel::Model(:drivers)
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  def validate
    super
    validates_presence %i[name email license_plate]
    validates_unique %i[email license_plate]
    validates_format(/\A[^@\s]+@[^@\s]+\z/, :email, message: 'is not a valid email') if email
  end
end
