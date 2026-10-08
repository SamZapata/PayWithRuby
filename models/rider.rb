# frozen_string_literal: true

# Domain model for riders. Table mapping + associations only.
# Input validation lives in validators/rider_validator.rb.

class Rider < Sequel::Model(:riders)
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  many_to_one :user

  def validate
    super
    validates_presence %i[name email]
    validates_unique :email
    validates_unique :user_id unless user_id.nil?
    validates_format(/\A[^@\s]+@[^@\s]+\z/, :email, message: 'is not a valid email') if email
  end
end
