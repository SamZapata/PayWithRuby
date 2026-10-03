# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /api/v1/health' do
  it 'returns 200 with status ok through Controller -> Service -> Serializer' do
    get '/api/v1/health'

    expect(last_response.status).to eq(200)
    expect(last_response.content_type).to include('application/json')

    body = JSON.parse(last_response.body)
    expect(body['data']['status']).to eq('ok')
    expect(body['data']['version']).to eq('v1')
    expect(body['data']).to have_key('time')
  end
end
