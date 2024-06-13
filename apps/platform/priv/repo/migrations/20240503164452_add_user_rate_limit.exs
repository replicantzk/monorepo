defmodule Platform.Repo.Migrations.AddUserRateLimit do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :rate_limit, :integer, default: 10
    end
  end
end
