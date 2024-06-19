defmodule Platform.Repo.Migrations.RequestsAddClientId do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :client_id, :string
    end
  end
end
