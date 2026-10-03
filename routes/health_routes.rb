# frozen_string_literal: true

# HTTP mapping only. No business logic here (see AGENTS.md §5).
# Validator skipped for health: no input params to validate.
# Repository/Model skipped: health does not touch the database.

class App
  get '/api/v1/health' do
    status_code, body = HealthController.check
    status status_code
    body.to_json
  end
end
