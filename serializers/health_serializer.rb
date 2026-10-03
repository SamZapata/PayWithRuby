# frozen_string_literal: true

# JSON presentation for health. Formatting only, no logic.

module HealthSerializer
  def self.to_h(payload)
    {
      data: {
        status: payload[:status],
        version: payload[:version],
        time: payload[:time]
      }
    }
  end
end
