# frozen_string_literal: true

# Persistence isolation for rides. Encapsulates Sequel queries.
# No business logic, no HTTP. Returns Sequel models (or nil).

class RideRepository
  def self.all(status: nil, rider_id: nil, driver_id: nil)
    ds = Ride.order(:id)
    ds = ds.where(status: status.to_s) unless status.nil? || status.to_s.empty?
    ds = ds.where(rider_id: rider_id) unless rider_id.nil? || rider_id.to_s.empty?
    ds = ds.where(driver_id: driver_id) unless driver_id.nil? || driver_id.to_s.empty?
    ds.all
  end

  def self.find(id)
    Ride[id]
  end

  def self.create(attrs)
    Ride.create(symbolize(attrs))
  end

  def self.update(id, attrs)
    ride = find(id)
    return nil if ride.nil?

    ride.update(symbolize(attrs))
    ride.refresh
  end

  def self.symbolize(hash)
    hash.transform_keys(&:to_sym)
  end
end
