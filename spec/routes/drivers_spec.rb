# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Drivers CRUD' do
  def json_headers
    { 'CONTENT_TYPE' => 'application/json' }
  end

  it 'creates a driver (201) and requires license_plate (422 without it)' do
    post '/api/v1/drivers',
         { name: 'Carlos Driver', email: 'carlos.driver@example.com', license_plate: 'ABC123', vehicle_model: 'Mazda 3' }.to_json,
         json_headers
    expect(last_response.status).to eq(201)
    body = JSON.parse(last_response.body)
    expect(body['data']['license_plate']).to eq('ABC123')

    post '/api/v1/drivers', { name: 'No Plate', email: 'noplate@example.com' }.to_json, json_headers
    expect(last_response.status).to eq(422)
  end

  it 'lists, shows, updates and soft-deletes drivers (200 + inactive, record kept)' do
    post '/api/v1/drivers',
         { name: 'Maria', email: 'maria@example.com', license_plate: 'XYZ999' }.to_json,
         json_headers
    id = JSON.parse(last_response.body)['data']['id']

    get '/api/v1/drivers'
    expect(last_response.status).to eq(200)

    get "/api/v1/drivers/#{id}"
    expect(last_response.status).to eq(200)

    patch "/api/v1/drivers/#{id}", { vehicle_model: 'Renault Logan' }.to_json, json_headers
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)['data']['vehicle_model']).to eq('Renault Logan')

    delete "/api/v1/drivers/#{id}"
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
