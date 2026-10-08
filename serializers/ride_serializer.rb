# frozen_string_literal: true

# JSON presentation for rides. Formatting only, no logic.

module RideSerializer
  def self.to_h(ride)
    {
      id: ride.id,
      rider_id: ride.rider_id,
      driver_id: ride.driver_id,
      origin: ride.origin,
      destination: ride.destination,
      price: ride.price,
      status: ride.status,
      created_at: ride.created_at&.utc&.iso8601,
      updated_at: ride.updated_at&.utc&.iso8601
    }
  end

  def self.list_to_h(rides)
    rides.map { |r| to_h(r) }
  end
end
