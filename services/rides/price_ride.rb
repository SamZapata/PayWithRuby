# frozen_string_literal: true

# Business rule: deterministic fare in COP pesos (integer, no cents).
# Base 5000 + 100 per character of origin + destination.
# Pure function: no DB, no HTTP. Easy to unit test, replaceable later.

module Rides
  module PriceRide
    BASE = 5_000
    PER_CHAR = 100

    def self.call(origin, destination)
      BASE + (PER_CHAR * (origin.to_s.length + destination.to_s.length))
    end
  end
end
