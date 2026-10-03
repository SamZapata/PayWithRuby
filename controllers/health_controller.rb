# frozen_string_literal: true

# HTTP coordination for health.
# Owns status code, calls Service + Serializer. No business rules, no SQL.

class HealthController
  def self.check
    payload = Health::CheckService.call
    [200, HealthSerializer.to_h(payload)]
  end
end
