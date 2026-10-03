# frozen_string_literal: true

# Business operation for health check.
# No DB, no external calls. Keeps business logic out of routes/controllers.

module Health
  class CheckService
    def self.call
      {
        status: 'ok',
        version: 'v1',
        time: Time.now.utc.iso8601
      }
    end
  end
end
