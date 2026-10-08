# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Riders CRUD' do
  def json_headers
    { 'CONTENT_TYPE' => 'application/json' }
  end

  def auth_headers(email: "rider.#{rand(1_000_000)}@example.com", role: 'rider')
    post '/api/v1/auth/signup', { email: email, password: 'secret123', role: role }.to_json, json_headers
    token = JSON.parse(last_response.body).dig('data', 'token')
    json_headers.merge('HTTP_AUTHORIZATION' => "Bearer #{token}")
  end

  it 'creates a rider (201) and rejects invalid input (422)' do
    headers = auth_headers
    post '/api/v1/riders', { name: 'Ana Rider', email: 'ana.rider@example.com', phone: '3001112233' }.to_json, headers
    expect(last_response.status).to eq(201)
    body = JSON.parse(last_response.body)
    expect(body['data']['email']).to eq('ana.rider@example.com')
    expect(body['data']['id']).not_to be_nil
    expect(body['data']['user_id']).not_to be_nil

    # Fresh user so we hit input validation, not duplicate-profile guard.
    post '/api/v1/riders', { name: '', email: 'bad' }.to_json, auth_headers
    expect(last_response.status).to eq(422)
  end

  it 'rejects duplicate email across users (422)' do
    headers = auth_headers
    post '/api/v1/riders', { name: 'Dup', email: 'dup@example.com' }.to_json, headers
    expect(last_response.status).to eq(201)

    post '/api/v1/riders', { name: 'Dup2', email: 'dup@example.com' }.to_json, auth_headers
    expect(last_response.status).to eq(422)
  end

  it 'rejects a second profile for the same user (422)' do
    headers = auth_headers
    post '/api/v1/riders', { name: 'First', email: 'first@example.com' }.to_json, headers
    expect(last_response.status).to eq(201)

    post '/api/v1/riders', { name: 'Second', email: 'second@example.com' }.to_json, headers
    expect(last_response.status).to eq(422)
    expect(JSON.parse(last_response.body).dig('error', 'details', 'user')).not_to be_nil
  end

  it 'rejects rider creation with a driver token (403)' do
    headers = auth_headers(role: 'driver')
    post '/api/v1/riders', { name: 'Cross', email: 'cross@example.com' }.to_json, headers
    expect(last_response.status).to eq(403)
  end

  it 'lists, shows, updates and soft-deletes riders (200 + inactive, record kept)' do
    headers = auth_headers
    post '/api/v1/riders', { name: 'Luis', email: 'luis@example.com' }.to_json, headers
    id = JSON.parse(last_response.body)['data']['id']

    get '/api/v1/riders'
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']).not_to be_empty

    get "/api/v1/riders/#{id}"
    expect(last_response.status).to eq(200)

    get '/api/v1/riders/999999'
    expect(last_response.status).to eq(404)

    patch "/api/v1/riders/#{id}", { phone: '3009998877' }.to_json, headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['phone']).to eq('3009998877')

    delete "/api/v1/riders/#{id}", nil, headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('inactive')

    # Record kept: still GET-able with inactive status...
    get "/api/v1/riders/#{id}"
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('inactive')

    # ...but hidden from default list, visible with ?status= filter
    get '/api/v1/riders'
    ids = JSON.parse(last_response.body)['data'].map { |r| r['id'] }
    expect(ids).not_to include(id)

    get '/api/v1/riders?status=inactive'
    ids = JSON.parse(last_response.body)['data'].map { |r| r['id'] }
    expect(ids).to include(id)
  end

  it 'rejects updates and deletes from a non-owner (403)' do
    headers = auth_headers
    post '/api/v1/riders', { name: 'Owner', email: 'owner@example.com' }.to_json, headers
    id = JSON.parse(last_response.body)['data']['id']

    other = auth_headers
    patch "/api/v1/riders/#{id}", { phone: '3000000000' }.to_json, other
    expect(last_response.status).to eq(403)

    delete "/api/v1/riders/#{id}", nil, other
    expect(last_response.status).to eq(403)
  end
end
