defmodule Platform.Repo.Migrations.AddRequestType do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :type, :string
    end
  end
end
