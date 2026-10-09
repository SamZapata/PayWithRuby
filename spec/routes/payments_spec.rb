# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Payments via Wompi (mocked)' do
  def json_headers
    { 'CONTENT_TYPE' => 'application/json' }
  end

  def signup(email:, role:)
    post '/api/v1/auth/signup', { email: email, password: 'secret123', role: role }.to_json, json_headers
    body = JSON.parse(last_response.body)
    [body.dig('data', 'token'), body.dig('data', 'user', 'id')]
  end

  def headers_for(token)
    json_headers.merge('HTTP_AUTHORIZATION' => "Bearer #{token}")
  end

  def setup_completed_ride(suffix)
    rider_token, = signup(email: "pay.rider.#{suffix}@example.com", role: 'rider')
    driver_token, = signup(email: "pay.driver.#{suffix}@example.com", role: 'driver')

    post '/api/v1/riders', { name: 'Rider', email: "pay.profile.rider.#{suffix}@example.com" }.to_json, headers_for(rider_token)
    rider_id = JSON.parse(last_response.body)['data']['id']

    post '/api/v1/drivers',
         { name: 'Driver', email: "pay.profile.driver.#{suffix}@example.com", license_plate: "PAY#{suffix}" }.to_json,
         headers_for(driver_token)
    driver_id = JSON.parse(last_response.body)['data']['id']

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'Zona Rosa', destination: 'Chapinero' }.to_json,
         headers_for(rider_token)
    ride = JSON.parse(last_response.body)['data']

    patch "/api/v1/rides/#{ride['id']}/accept", { driver_id: driver_id }.to_json, headers_for(driver_token)
    patch "/api/v1/rides/#{ride['id']}/complete", nil, headers_for(driver_token)

    [rider_token, driver_token, ride['id'], ride['price']]
  end

  it 'charges a completed ride (201) with mocked transaction, amount = ride price' do
    rider_token, _, ride_id, price = setup_completed_ride(rand(1_000_000))

    post '/api/v1/payments', { ride_id: ride_id }.to_json, headers_for(rider_token)
    expect(last_response.status).to eq(201)
    body = JSON.parse(last_response.body)['data']
    expect(body['ride_id']).to eq(ride_id)
    expect(body['amount']).to eq(price)
    expect(body['status']).to eq('pending')
    expect(body['wompi_transaction_id']).to start_with('mock-')
    expect(body['idempotency_key']).to eq("pay-ride-#{ride_id}")
  end

  it 'is idempotent: replaying the same ride returns 200 with the same transaction' do
    rider_token, _, ride_id, = setup_completed_ride(rand(1_000_000))

    post '/api/v1/payments', { ride_id: ride_id }.to_json, headers_for(rider_token)
    first = JSON.parse(last_response.body)['data']

    post '/api/v1/payments', { ride_id: ride_id }.to_json, headers_for(rider_token)
    expect(last_response.status).to eq(200)
    second = JSON.parse(last_response.body)['data']
    expect(second['id']).to eq(first['id'])
    expect(second['wompi_transaction_id']).to eq(first['wompi_transaction_id'])
  end

  it 'rejects charging non-completed rides (422) and unknown rides (404)' do
    # Create a fresh requested (non-completed) ride directly.
    rider_token2, = signup(email: "fresh.rider.#{rand(1_000_000)}@example.com", role: 'rider')
    post '/api/v1/riders', { name: 'Fresh', email: "fresh.p.#{rand(1_000_000)}@example.com" }.to_json, headers_for(rider_token2)
    fresh_rider_id = JSON.parse(last_response.body)['data']['id']
    post '/api/v1/rides', { rider_id: fresh_rider_id, origin: 'A', destination: 'B' }.to_json, headers_for(rider_token2)
    requested_id = JSON.parse(last_response.body)['data']['id']

    post '/api/v1/payments', { ride_id: requested_id }.to_json, headers_for(rider_token2)
    expect(last_response.status).to eq(422)

    post '/api/v1/payments', { ride_id: 999_999 }.to_json, headers_for(rider_token2)
    expect(last_response.status).to eq(404)

    post '/api/v1/payments', {}.to_json, headers_for(rider_token2)
    expect(last_response.status).to eq(422)
  end

  it 'rejects foreign riders, drivers, and anonymous callers (403/401)' do
    rider_token, driver_token, ride_id, = setup_completed_ride(rand(1_000_000))

    other_token, = signup(email: "stranger.r.#{rand(1_000_000)}@example.com", role: 'rider')
    post '/api/v1/riders', { name: 'Stranger', email: "stranger.p.#{rand(1_000_000)}@example.com" }.to_json, headers_for(other_token)
    post '/api/v1/payments', { ride_id: ride_id }.to_json, headers_for(other_token)
    expect(last_response.status).to eq(403)

    post '/api/v1/payments', { ride_id: ride_id }.to_json, headers_for(driver_token)
    expect(last_response.status).to eq(403)

    post '/api/v1/payments', { ride_id: ride_id }.to_json, json_headers
    expect(last_response.status).to eq(401)
  end

  it 'confirms via public webhook: pending -> approved, visible on GET' do
    rider_token, _, ride_id, = setup_completed_ride(rand(1_000_000))

    post '/api/v1/payments', { ride_id: ride_id }.to_json, headers_for(rider_token)
    payment = JSON.parse(last_response.body)['data']
    tx = payment['wompi_transaction_id']

    # Webhook is public: no Authorization header.
    post '/api/v1/payments/webhook', { transaction_id: tx, status: 'approved' }.to_json, json_headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('approved')

    get "/api/v1/payments/#{payment['id']}", nil, headers_for(rider_token)
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('approved')

    # Replay same terminal status is idempotent.
    post '/api/v1/payments/webhook', { transaction_id: tx, status: 'approved' }.to_json, json_headers
    expect(last_response.status).to eq(200)
  end

  it 'handles declined webhook and rejects bad webhooks (404/422)' do
    rider_token, _, ride_id, = setup_completed_ride(rand(1_000_000))

    post '/api/v1/payments', { ride_id: ride_id }.to_json, headers_for(rider_token)
    tx = JSON.parse(last_response.body)['data']['wompi_transaction_id']

    post '/api/v1/payments/webhook', { transaction_id: tx, status: 'declined' }.to_json, json_headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('declined')

    post '/api/v1/payments/webhook', { transaction_id: 'mock-does-not-exist', status: 'approved' }.to_json, json_headers
    expect(last_response.status).to eq(404)

    post '/api/v1/payments/webhook', { transaction_id: tx, status: 'bogus' }.to_json, json_headers
    expect(last_response.status).to eq(422)

    post '/api/v1/payments/webhook', { status: 'approved' }.to_json, json_headers
    expect(last_response.status).to eq(422)
  end
end
