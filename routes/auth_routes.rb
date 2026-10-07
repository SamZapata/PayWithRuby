# frozen_string_literal: true

# HTTP mapping for auth. No business logic (see AGENTS.md §5).
# Public endpoints: signup + login. No auth required here.

class App
  post '/api/v1/auth/signup' do
    status_code, body = AuthController.signup(json_attrs)
    render_result(status_code, body)
  end

  post '/api/v1/auth/login' do
    status_code, body = AuthController.login(json_attrs)
    render_result(status_code, body)
  end
end
