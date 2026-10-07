# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :email, null: false, unique: true, size: 255
      String :password_hash, null: false, size: 255
      String :role, null: false, default: 'rider', size: 20
      String :status, null: false, default: 'active', size: 20
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
