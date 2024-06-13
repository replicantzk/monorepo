defmodule Platform.Repo.Migrations.AddRequestType do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :request_type, :string
    end
  end
end
