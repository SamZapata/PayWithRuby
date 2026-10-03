# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RiderValidator do
  it 'requires name and valid email on create' do
    expect(described_class.validate_create({ name: 'A', email: 'a@example.com' })[:ok]).to be(true)
    expect(described_class.validate_create({ name: '', email: 'bad' })[:ok]).to be(false)
    expect(described_class.validate_create({})[:ok]).to be(false)
  end

  it 'rejects unknown attributes and empty update' do
    expect(described_class.validate_create({ name: 'A', email: 'a@example.com', hacker: 1 })[:ok]).to be(false)
    expect(described_class.validate_update({})[:ok]).to be(false)
  end

  it 'rejects overlong fields matching DB sizes (name 100, phone 30)' do
    long_name = 'A' * 101
    result = described_class.validate_create({ name: long_name, email: 'a@example.com' })
    expect(result[:ok]).to be(false)
    expect(result[:errors][:name]).to include('maximum 100')

    result = described_class.validate_update({ phone: '1' * 31 })
    expect(result[:ok]).to be(false)
  end
end

RSpec.describe DriverValidator do
  it 'requires license_plate on create' do
    expect(described_class.validate_create({ name: 'D', email: 'd@example.com', license_plate: 'AAA111' })[:ok]).to be(true)
    expect(described_class.validate_create({ name: 'D', email: 'd@example.com' })[:ok]).to be(false)
  end

  it 'rejects overlong license_plate (max 20) and vehicle_model (max 100)' do
    result = described_class.validate_create({ name: 'D', email: 'd@example.com', license_plate: 'X' * 21 })
    expect(result[:ok]).to be(false)
    expect(result[:errors][:license_plate]).to include('maximum 20')
  end
end
