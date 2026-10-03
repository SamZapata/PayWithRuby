# frozen_string_literal: true

# Persistence isolation for riders. Encapsulates Sequel queries.
# No business logic, no HTTP. Returns Sequel models (or nil).

class RiderRepository
  # Default: active only. Pass status: 'all' or 'inactive' to override.
  def self.all(status: nil)
    ds = Rider.order(:id)
    ds = ds.where(status: 'active') if status.nil? || status.to_s.empty?
    ds = ds.where(status: status.to_s) if %w[active inactive].include?(status.to_s)
    ds.all
  end

  def self.find(id)
    Rider[id]
  end

  def self.create(attrs)
    Rider.create(symbolize(attrs))
  end

  def self.update(id, attrs)
    rider = find(id)
    return nil if rider.nil?

    rider.update(symbolize(attrs))
    rider.refresh
  end

  # Soft delete: keep the record, flip status to inactive.
  def self.deactivate(id)
    rider = find(id)
    return nil if rider.nil?

    rider.update(status: 'inactive')
    rider.refresh
  end

  # Hard delete kept for console/specs only. Controllers must use deactivate.
  def self.delete(id)
    rider = find(id)
    return false if rider.nil?

    rider.delete
    true
  end

  def self.symbolize(hash)
    hash.transform_keys(&:to_sym)
  end
end
