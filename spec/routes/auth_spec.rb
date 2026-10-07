# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Auth (JWT)' do
  def json_headers
    { 'CONTENT_TYPE' => 'application/json' }
  end

  def signup(email: 'auth.user@example.com', password: 'secret123', role: 'rider')
    post '/api/v1/auth/signup', { email: email, password: password, role: role }.to_json, json_headers
  end

  def auth_headers_for(email: 'auth.user@example.com', password: 'secret123', role: 'rider')
    signup(email: email, password: password, role: role)
    body = JSON.parse(last_response.body)
    token = body.dig('data', 'token')
    json_headers.merge('HTTP_AUTHORIZATION' => "Bearer #{token}")
  end

  it 'signs up (201 with token) and rejects duplicate email (422)' do
    signup
    expect(last_response.status).to eq(201)
    body = JSON.parse(last_response.body)
    expect(body['data']['user']['email']).to eq('auth.user@example.com')
    expect(body['data']['token']).not_to be_nil
    expect(body['data']['user']).not_to have_key('password_hash')

    signup
    expect(last_response.status).to eq(422)
  end

  it 'rejects short password (422) and bad email (422)' do
    signup(email: 'short@example.com', password: 'short')
    expect(last_response.status).to eq(422)

    signup(email: 'bad', password: 'secret123')
    expect(last_response.status).to eq(422)
  end

  it 'logs in (200 with token) and rejects wrong password (401)' do
    signup(email: 'login@example.com')

    post '/api/v1/auth/login', { email: 'login@example.com', password: 'secret123' }.to_json, json_headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['token']).not_to be_nil

    post '/api/v1/auth/login', { email: 'login@example.com', password: 'wrongpass1' }.to_json, json_headers
    expect(last_response.status).to eq(401)

    post '/api/v1/auth/login', { email: 'login@example.com' }.to_json, json_headers
    expect(last_response.status).to eq(422)
  end

  it 'protects rider writes (401 without token) but keeps GET public' do
    post '/api/v1/riders', { name: 'No Auth', email: 'noauth@example.com' }.to_json, json_headers
    expect(last_response.status).to eq(401)

    get '/api/v1/riders'
    expect(last_response.status).to eq(200)

    headers = auth_headers_for(email: 'rider.prot@example.com')
    post '/api/v1/riders', { name: 'With Auth', email: 'withauth@example.com' }.to_json, headers
    expect(last_response.status).to eq(201)
    id = JSON.parse(last_response.body)['data']['id']

    patch "/api/v1/riders/#{id}", { phone: '3001112233' }.to_json, json_headers
    expect(last_response.status).to eq(401)

    patch "/api/v1/riders/#{id}", { phone: '3001112233' }.to_json, headers
    expect(last_response.status).to eq(200)
  end

  it 'protects driver writes and rejects invalid/expired tokens (401)' do
    post '/api/v1/drivers',
         { name: 'No Auth', email: 'noauth.d@example.com', license_plate: 'AAA111' }.to_json,
         json_headers
    expect(last_response.status).to eq(401)

    get '/api/v1/drivers'
    expect(last_response.status).to eq(200)

    post '/api/v1/drivers',
         { name: 'Bad Token', email: 'bad.t@example.com', license_plate: 'BBB222' }.to_json,
         json_headers.merge('HTTP_AUTHORIZATION' => 'Bearer invalid.token.here')
    expect(last_response.status).to eq(401)
  end
end
