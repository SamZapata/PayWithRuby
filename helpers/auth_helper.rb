# frozen_string_literal: true

# Sinatra helpers for JWT auth. HTTP concern only.
# require_auth! halts with 401 when token is missing/invalid/expired.

module AuthHelpers
  def current_token_payload
    value = request.env['HTTP_AUTHORIZATION'].to_s
    return nil if value.empty?

    scheme, _, token = value.partition(' ')
    return nil unless scheme.casecmp('bearer').zero?
    return nil if token.strip.empty?

    Auth::Tokens.decode(token.strip)
  end

  def current_user
    payload = current_token_payload
    return nil if payload.nil?

    @current_user ||= User[payload['user_id'] || payload[:user_id]]
  end

  def require_auth!
    payload = current_token_payload
    if payload.nil?
      halt 401, { error: { code: 'unauthorized', message: 'Missing or invalid token' } }.to_json
    end

    user = User[payload['user_id'] || payload[:user_id]]
    if user.nil? || user.status != 'active'
      halt 401, { error: { code: 'unauthorized', message: 'Missing or invalid token' } }.to_json
    end

    @current_user = user
  end
end
