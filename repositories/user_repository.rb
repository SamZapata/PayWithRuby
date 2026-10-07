# frozen_string_literal: true

# Persistence isolation for users. Encapsulates Sequel queries.
# No business logic, no HTTP. Returns Sequel models (or nil).

class UserRepository
  def self.find(id)
    User[id]
  end

  def self.find_by_email(email)
    return nil if email.nil? || email.to_s.strip.empty?

    User.where(Sequel.function(:lower, :email) => email.to_s.strip.downcase).first
  end

  def self.create(attrs)
    User.create(symbolize(attrs))
  end

  def self.symbolize(hash)
    hash.transform_keys(&:to_sym)
  end
end
