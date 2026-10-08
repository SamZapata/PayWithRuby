# frozen_string_literal: true

# Persistence isolation for drivers. Encapsulates Sequel queries.

class DriverRepository
  # Default: active only. Pass status: 'all' or 'inactive' to override.
  def self.all(status: nil)
    ds = Driver.order(:id)
    ds = ds.where(status: 'active') if status.nil? || status.to_s.empty?
    ds = ds.where(status: status.to_s) if %w[active inactive].include?(status.to_s)
    ds.all
  end

  def self.find(id)
    Driver[id]
  end

  def self.find_by_user(user_id)
    Driver.where(user_id: user_id).first
  end

  def self.create(attrs)
    Driver.create(symbolize(attrs))
  end

  def self.update(id, attrs)
    driver = find(id)
    return nil if driver.nil?

    driver.update(symbolize(attrs))
    driver.refresh
  end

  # Soft delete: keep the record, flip status to inactive.
  def self.deactivate(id)
    driver = find(id)
    return nil if driver.nil?

    driver.update(status: 'inactive')
    driver.refresh
  end

  # Hard delete kept for console/specs only. Controllers must use deactivate.
  def self.delete(id)
    driver = find(id)
    return false if driver.nil?

    driver.delete
    true
  end

  def self.symbolize(hash)
    hash.transform_keys(&:to_sym)
  end
end
