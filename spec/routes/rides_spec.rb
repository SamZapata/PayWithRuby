# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rides lifecycle' do
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

  def setup_pair(suffix)
    rider_token, = signup(email: "rider.#{suffix}@example.com", role: 'rider')
    driver_token, = signup(email: "driver.#{suffix}@example.com", role: 'driver')

    post '/api/v1/riders', { name: 'Rider', email: "profile.rider.#{suffix}@example.com" }.to_json, headers_for(rider_token)
    rider_id = JSON.parse(last_response.body)['data']['id']

    post '/api/v1/drivers',
         { name: 'Driver', email: "profile.driver.#{suffix}@example.com", license_plate: "PLT#{suffix}" }.to_json,
         headers_for(driver_token)
    driver_id = JSON.parse(last_response.body)['data']['id']

    [rider_token, driver_token, rider_id, driver_id]
  end

  it 'creates a ride (201) with COP price formula' do
    rider_token, _, rider_id, = setup_pair(rand(1_000_000))

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'Zona Rosa', destination: 'Chapinero' }.to_json,
         headers_for(rider_token)
    expect(last_response.status).to eq(201)
    body = JSON.parse(last_response.body)
    expect(body['data']['status']).to eq('requested')
    expect(body['data']['driver_id']).to be_nil
    # 5000 + 100 * (9 + 9) = 6800
    expect(body['data']['price']).to eq(5_000 + 100 * ('Zona Rosa'.length + 'Chapinero'.length))
  end

  it 'rejects ride creation with invalid input (422) and unknown ride (404)' do
    rider_token, _, rider_id, = setup_pair(rand(1_000_000))

    post '/api/v1/rides', { rider_id: rider_id, origin: '' }.to_json, headers_for(rider_token)
    expect(last_response.status).to eq(422)

    get '/api/v1/rides/999999'
    expect(last_response.status).to eq(404)
  end

  it 'rejects ride creation from drivers and foreign rider_ids (403)' do
    rider_token, driver_token, rider_id, = setup_pair(rand(1_000_000))

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'A', destination: 'B' }.to_json,
         headers_for(driver_token)
    expect(last_response.status).to eq(403)

    other_token, = signup(email: "other.rider.#{rand(1_000_000)}@example.com", role: 'rider')
    post '/api/v1/riders', { name: 'Other', email: "other.profile.#{rand(1_000_000)}@example.com" }.to_json, headers_for(other_token)

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'A', destination: 'B' }.to_json,
         headers_for(other_token)
    expect(last_response.status).to eq(403)

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'A', destination: 'B' }.to_json,
         json_headers
    expect(last_response.status).to eq(401)
  end

  it 'runs the full lifecycle requested -> accepted -> completed' do
    rider_token, driver_token, rider_id, driver_id = setup_pair(rand(1_000_000))

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'Parque 93', destination: 'Usaquen' }.to_json,
         headers_for(rider_token)
    ride_id = JSON.parse(last_response.body)['data']['id']

    patch "/api/v1/rides/#{ride_id}/accept", { driver_id: driver_id }.to_json, headers_for(driver_token)
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('accepted')
    expect(JSON.parse(last_response.body)['data']['driver_id']).to eq(driver_id)

    # Double accept is rejected.
    patch "/api/v1/rides/#{ride_id}/accept", { driver_id: driver_id }.to_json, headers_for(driver_token)
    expect(last_response.status).to eq(422)

    patch "/api/v1/rides/#{ride_id}/complete", nil, headers_for(driver_token)
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('completed')

    # Terminal state: cancel rejected.
    patch "/api/v1/rides/#{ride_id}/cancel", nil, headers_for(rider_token)
    expect(last_response.status).to eq(422)
  end

  it 'rejects complete without accept (422) and foreign driver accept (403)' do
    rider_token, driver_token, rider_id, driver_id = setup_pair(rand(1_000_000))

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'A', destination: 'B' }.to_json,
         headers_for(rider_token)
    ride_id = JSON.parse(last_response.body)['data']['id']

    patch "/api/v1/rides/#{ride_id}/complete", nil, headers_for(driver_token)
    expect(last_response.status).to eq(422)

    other_token, = signup(email: "other.driver.#{rand(1_000_000)}@example.com", role: 'driver')
    post '/api/v1/drivers',
         { name: 'Other', email: "other.dprofile.#{rand(1_000_000)}@example.com", license_plate: "FOR#{rand(1_000_000)}" }.to_json,
         headers_for(other_token)
    other_driver_id = JSON.parse(last_response.body)['data']['id']

    patch "/api/v1/rides/#{ride_id}/accept", { driver_id: other_driver_id }.to_json, headers_for(other_token)
    expect(last_response.status).to eq(200)

    # Original driver no longer owns this ride.
    patch "/api/v1/rides/#{ride_id}/complete", nil, headers_for(driver_token)
    expect(last_response.status).to eq(403)

    patch "/api/v1/rides/#{ride_id}/complete", nil, headers_for(other_token)
    expect(last_response.status).to eq(200)
    expect(driver_id).not_to eq(other_driver_id)
  end

  it 'cancels requested and accepted rides, owner-only (403 otherwise)' do
    rider_token, driver_token, rider_id, driver_id = setup_pair(rand(1_000_000))

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'A', destination: 'B' }.to_json,
         headers_for(rider_token)
    requested_id = JSON.parse(last_response.body)['data']['id']

    # Non-owner rider cannot cancel.
    other_token, = signup(email: "stranger.#{rand(1_000_000)}@example.com", role: 'rider')
    post '/api/v1/riders', { name: 'Stranger', email: "stranger.p.#{rand(1_000_000)}@example.com" }.to_json, headers_for(other_token)
    patch "/api/v1/rides/#{requested_id}/cancel", nil, headers_for(other_token)
    expect(last_response.status).to eq(403)

    patch "/api/v1/rides/#{requested_id}/cancel", nil, headers_for(rider_token)
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('cancelled')

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'C', destination: 'D' }.to_json,
         headers_for(rider_token)
    accepted_id = JSON.parse(last_response.body)['data']['id']
    patch "/api/v1/rides/#{accepted_id}/accept", { driver_id: driver_id }.to_json, headers_for(driver_token)
    expect(last_response.status).to eq(200)

    patch "/api/v1/rides/#{accepted_id}/cancel", nil, headers_for(driver_token)
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('cancelled')
  end

  it 'lists with status and rider filters, rejects bad status (422)' do
    rider_token, _, rider_id, = setup_pair(rand(1_000_000))

    post '/api/v1/rides',
         { rider_id: rider_id, origin: 'X', destination: 'Y' }.to_json,
         headers_for(rider_token)
    ride_id = JSON.parse(last_response.body)['data']['id']

    get '/api/v1/rides'
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data'].map { |r| r['id'] }).to include(ride_id)

    get '/api/v1/rides?status=requested'
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data'].map { |r| r['id'] }).to include(ride_id)

    get '/api/v1/rides?status=completed'
    expect(JSON.parse(last_response.body)['data'].map { |r| r['id'] }).not_to include(ride_id)

    get "/api/v1/rides?rider_id=#{rider_id}"
    expect(JSON.parse(last_response.body)['data'].map { |r| r['id'] }).to include(ride_id)

    get '/api/v1/rides?status=bogus'
    expect(last_response.status).to eq(422)
  end
end
