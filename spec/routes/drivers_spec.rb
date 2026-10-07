# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Drivers CRUD' do
  def json_headers
    { 'CONTENT_TYPE' => 'application/json' }
  end

  def auth_headers(email: "driver.#{rand(1_000_000)}@example.com")
    post '/api/v1/auth/signup', { email: email, password: 'secret123', role: 'driver' }.to_json, json_headers
    token = JSON.parse(last_response.body).dig('data', 'token')
    json_headers.merge('HTTP_AUTHORIZATION' => "Bearer #{token}")
  end

  it 'creates a driver (201) and requires license_plate (422 without it)' do
    headers = auth_headers
    post '/api/v1/drivers',
         { name: 'Carlos Driver', email: 'carlos.driver@example.com', license_plate: 'ABC123', vehicle_model: 'Mazda 3' }.to_json,
         headers
    expect(last_response.status).to eq(201)
    body = JSON.parse(last_response.body)
    expect(body['data']['license_plate']).to eq('ABC123')

    post '/api/v1/drivers', { name: 'No Plate', email: 'noplate@example.com' }.to_json, headers
    expect(last_response.status).to eq(422)
  end

  it 'lists, shows, updates and soft-deletes drivers (200 + inactive, record kept)' do
    headers = auth_headers
    post '/api/v1/drivers',
         { name: 'Maria', email: 'maria@example.com', license_plate: 'XYZ999' }.to_json,
         headers
    id = JSON.parse(last_response.body)['data']['id']

    get '/api/v1/drivers'
    expect(last_response.status).to eq(200)

    get "/api/v1/drivers/#{id}"
    expect(last_response.status).to eq(200)

    patch "/api/v1/drivers/#{id}", { vehicle_model: 'Renault Logan' }.to_json, headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['vehicle_model']).to eq('Renault Logan')

    delete "/api/v1/drivers/#{id}", nil, headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('inactive')

    get "/api/v1/drivers/#{id}"
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['status']).to eq('inactive')

    get '/api/v1/drivers'
    ids = JSON.parse(last_response.body)['data'].map { |d| d['id'] }
    expect(ids).not_to include(id)

    get '/api/v1/drivers?status=inactive'
    ids = JSON.parse(last_response.body)['data'].map { |d| d['id'] }
    expect(ids).to include(id)
  end
end
