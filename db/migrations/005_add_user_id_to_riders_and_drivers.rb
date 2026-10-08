# frozen_string_literal: true

# Link riders/drivers profiles to auth users for ownership checks.
# Nullable + unique to allow safe migrate (existing rows keep NULL).
# Multiple NULLs allowed in Postgres. Controllers inject user_id from JWT,
# never from client JSON. ON DELETE RESTRICT preserves history (ADR-009).

Sequel.migration do
  change do
    alter_table(:riders) do
      add_foreign_key :user_id, :users, null: true, on_delete: :restrict
      add_index :user_id, unique: true
    end

    alter_table(:drivers) do
      add_foreign_key :user_id, :users, null: true, on_delete: :restrict
      add_index :user_id, unique: true
    end
  end
end
